# frozen_string_literal: true

RSpec.describe 'Phone 2FA' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }
  let(:template) { create(:template, account:, author:, only_field_types: %w[text]) }
  let(:submission) { create(:submission, template:) }
  let(:submitter) do
    create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:, phone: '+12145550100',
                       preferences: { 'require_phone_2fa' => true })
  end
  let(:sms_bodies) { [] }

  before do
    stub_const('ENV', ENV.to_h.merge('TWILIO_ACCOUNT_SID' => 'AC0', 'TWILIO_API_KEY_SID' => 'SK0',
                                     'TWILIO_API_KEY_SECRET' => 'secret', 'TWILIO_MESSAGING_SERVICE_SID' => 'MG0'))
    stub_request(:post, 'https://api.twilio.com/2010-04-01/Accounts/AC0/Messages.json').to_return do |request|
      sms_bodies << URI.decode_www_form(request.body).to_h
      { status: 201, body: '{}' }
    end
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  def pass_phone_2fa
    visit submit_form_path(slug: submitter.slug)

    click_button 'Send verification code'
    fill_in 'one_time_code', with: sms_bodies.last['Body'][/\d{6}/]
    click_button 'Submit'
  end

  it 'completes the form after the code from the SMS is entered' do
    visit submit_form_path(slug: submitter.slug)

    expect(page).to have_no_field('First Name')

    pass_phone_2fa

    expect(sms_bodies.last['To']).to eq('+12145550100')

    fill_in 'First Name', with: 'Mary'
    find('#submit_form_button').click

    expect(page).to have_content('Form has been completed!')
    expect(submitter.reload.completed_at).to be_present
    expect(submitter.submission_events.pluck(:event_type)).to include('send_2fa_sms', 'phone_verified')
  end

  it "doesn't open the form if the code is invalid" do
    visit submit_form_path(slug: submitter.slug)

    click_button 'Send verification code'
    fill_in 'one_time_code', with: '000000'
    click_button 'Submit'

    expect(page).to have_content 'Invalid code'
    expect(page).to have_no_field('First Name')
  end

  it 'shows the completed document after the code in a new browser' do
    submitter.update!(completed_at: Time.current)

    pass_phone_2fa

    expect(page).to have_current_path(submit_form_completed_path(submitter.slug))
    expect(page).to have_css('download-button')
  end

  it 'asks for a new code after the phone number changes' do
    pass_phone_2fa

    expect(page).to have_field('First Name')

    submitter.update!(phone: '+12145550199')
    visit submit_form_path(slug: submitter.slug)

    expect(page).to have_button('Send verification code')
    expect(page).to have_no_field('First Name')
  end
end
