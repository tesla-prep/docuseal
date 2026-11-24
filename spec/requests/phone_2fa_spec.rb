# frozen_string_literal: true

describe 'Phone 2FA code' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }
  let(:template) { create(:template, account:, author:) }
  let(:submission) { create(:submission, template:, created_by_user: author) }
  let(:submitter) do
    create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:, phone: '+12145550100',
                       preferences: { 'require_phone_2fa' => true })
  end
  let!(:twilio) do
    stub_request(:post, 'https://api.twilio.com/2010-04-01/Accounts/AC0/Messages.json')
      .to_return(status: 201, body: '{}')
  end

  before do
    stub_const('ENV', ENV.to_h.merge('TWILIO_ACCOUNT_SID' => 'AC0', 'TWILIO_API_KEY_SID' => 'SK0',
                                     'TWILIO_API_KEY_SECRET' => 'secret', 'TWILIO_MESSAGING_SERVICE_SID' => 'MG0'))
  end

  it 'texts the code while the invitation is open' do
    put '/submit_form_phone_2fa', params: { submitter_slug: submitter.slug }

    expect(twilio).to have_been_requested.once
    expect(response).to redirect_to(submit_form_path(submitter.slug, status: :sent))
  end

  it 'texts nothing when phone 2FA is not required' do
    submitter.update!(preferences: {})

    put '/submit_form_phone_2fa', params: { submitter_slug: submitter.slug }

    expect(twilio).not_to have_been_requested
    expect(response).to redirect_to(submit_form_path(submitter.slug))
  end

  it 'texts nothing when the submission is archived or the signer has completed' do
    submission.update!(archived_at: Time.current)
    put '/submit_form_phone_2fa', params: { submitter_slug: submitter.slug }

    submission.update!(archived_at: nil)
    submitter.update!(completed_at: Time.current)
    put '/submit_form_phone_2fa', params: { submitter_slug: submitter.slug }

    expect(twilio).not_to have_been_requested
  end

  it 'records no verification when phone 2FA is not required' do
    submitter.update!(preferences: {})

    post '/submit_form_phone_2fa', params: { submitter_slug: submitter.slug, one_time_code: '123456' }

    expect(submitter.submission_events.where(event_type: 'phone_verified')).to be_empty
  end
end
