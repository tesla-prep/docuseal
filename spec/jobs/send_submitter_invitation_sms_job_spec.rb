# frozen_string_literal: true

RSpec.describe SendSubmitterInvitationSmsJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user, submitter_count: 2) }
  let(:submission) do
    create(:submission, :with_submitters, template:, created_by_user: user, submitters_order: 'preserved')
  end
  let(:first_submitter) { submission.submitters.find_by(uuid: template.submitters.first['uuid']) }
  let(:second_submitter) { submission.submitters.find_by(uuid: template.submitters.second['uuid']) }
  let(:twilio_env) do
    { 'TWILIO_ACCOUNT_SID' => 'AC0', 'TWILIO_API_KEY_SID' => 'SK0', 'TWILIO_API_KEY_SECRET' => 'secret',
      'TWILIO_MESSAGING_SERVICE_SID' => 'MG0' }
  end

  before do
    first_submitter.update!(phone: '+12145550100', sent_at: nil, preferences: { 'send_sms' => true })
    second_submitter.update!(phone: '+12145550101', sent_at: nil, preferences: { 'send_sms' => true })
  end

  it 'texts the invitation link and marks the signer as sent' do
    stub_const('ENV', ENV.to_h.merge(twilio_env))
    link = %r{https?://\S+/s/#{first_submitter.slug}}
    body = /\A#{Regexp.escape(account.name)} has invited you to sign a document: #{link}\z/
    twilio = stub_request(:post, 'https://api.twilio.com/2010-04-01/Accounts/AC0/Messages.json')
             .with(basic_auth: %w[SK0 secret],
                   body: hash_including('To' => '+12145550100', 'MessagingServiceSid' => 'MG0', 'Body' => body))
             .to_return(status: 201, body: '{}')

    described_class.new.perform('submitter_id' => first_submitter.id)

    expect(twilio).to have_been_requested.once
    expect(first_submitter.submission_events.where(event_type: 'send_sms').count).to eq(1)
    expect(first_submitter.reload.sent_at).to be_present
  end

  it 'does not text a signer whose turn has not come, even when started by hand' do
    stub_const('ENV', ENV.to_h.merge(twilio_env))
    twilio = stub_request(:post, /api\.twilio\.com/)

    described_class.new.perform('submitter_id' => second_submitter.id)

    expect(twilio).not_to have_been_requested
    expect(second_submitter.reload.sent_at).to be_nil
  end

  it 'does not text when Twilio is not configured' do
    twilio = stub_request(:post, /api\.twilio\.com/)

    described_class.new.perform('submitter_id' => first_submitter.id)

    expect(twilio).not_to have_been_requested
    expect(first_submitter.reload.sent_at).to be_nil
  end

  it 'is enqueued only for the signer whose turn it is and only with send_sms' do
    stub_const('ENV', ENV.to_h.merge(twilio_env))

    Submissions.send_signature_requests([submission.reload])

    expect(described_class.jobs.map { |job| job['args'].first['submitter_id'] }).to eq([first_submitter.id])

    described_class.jobs.clear
    first_submitter.update!(preferences: { 'send_sms' => false })

    Submissions.send_signature_requests([submission.reload])

    expect(described_class.jobs).to be_empty
  end

  it 'is not enqueued when Twilio is not configured' do
    Submissions.send_signature_requests([submission.reload])

    expect(described_class.jobs).to be_empty
  end
end
