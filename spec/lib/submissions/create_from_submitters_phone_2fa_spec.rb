# frozen_string_literal: true

RSpec.describe Submissions::CreateFromSubmitters do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:uuid) { template.submitters.first['uuid'] }

  before do
    stub_const('ENV', ENV.to_h.merge('TWILIO_ACCOUNT_SID' => 'AC0', 'TWILIO_API_KEY_SID' => 'SK0',
                                     'TWILIO_API_KEY_SECRET' => 'secret', 'TWILIO_MESSAGING_SERVICE_SID' => 'MG0'))
  end

  def create_submissions(submissions_attrs, params = {})
    described_class.call(template:, user:, source: :invite, submitters_order: 'preserved',
                         submissions_attrs: submissions_attrs.map(&:with_indifferent_access),
                         params: { require_phone_2fa: '1' }.merge(params).with_indifferent_access)
  end

  it 'adds a view-only CC by email without asking it for a phone' do
    submissions = create_submissions([{ submitters: [{ uuid:, email: 'signer@example.com', phone: '+12145550100' }] }],
                                     cc_recipients: ['cc@example.com'])

    signer, cc = submissions.first.submitters.partition { |s| s.email == 'signer@example.com' }.map(&:first)

    expect(Submitters::AuthorizedForForm.phone_2fa_required?(signer)).to be(true)
    expect(cc.viewer?).to be(true)
    expect(Submitters::AuthorizedForForm.phone_2fa_required?(cc)).to be(false)
  end

  it 'keeps an explicit phone 2FA on a view-only role' do
    viewer_uuid = SecureRandom.uuid
    template.update!(submitters: template.submitters + [{ 'name' => 'Viewer', 'uuid' => viewer_uuid }])

    submissions = create_submissions([{ submitters: [
                                       { uuid:, email: 'signer@example.com', phone: '+12145550100' },
                                       { uuid: viewer_uuid, email: 'viewer@example.com', phone: '+12145550101',
                                         require_phone_2fa: true }
                                     ] }], require_phone_2fa: '0')

    viewer = submissions.first.submitters.find { |s| s.email == 'viewer@example.com' }

    expect(viewer.viewer?).to be(true)
    expect(Submitters::AuthorizedForForm.phone_2fa_required?(viewer)).to be(true)
  end

  it 'does not ask a view-only role for a phone under the shared flag' do
    viewer_uuid = SecureRandom.uuid
    template.update!(submitters: template.submitters + [{ 'name' => 'Viewer', 'uuid' => viewer_uuid }])

    submissions = create_submissions([{ submitters: [
                                       { uuid:, email: 'signer@example.com', phone: '+12145550100' },
                                       { uuid: viewer_uuid, email: 'viewer@example.com' }
                                     ] }])

    signer, viewer = submissions.first.submitters.partition { |s| s.email == 'signer@example.com' }.map(&:first)

    expect(Submitters::AuthorizedForForm.phone_2fa_required?(signer)).to be(true)
    expect(viewer.viewer?).to be(true)
    expect(Submitters::AuthorizedForForm.phone_2fa_required?(viewer)).to be(false)
  end

  it 'saves no submission of a batch when one signer has no phone' do
    expect do
      create_submissions([{ submitters: [{ uuid:, email: 'first@example.com', phone: '+12145550100' }] },
                          { submitters: [{ uuid:, email: 'second@example.com' }] }])
    end.to raise_error(described_class::BaseError, 'Phone 2FA needs a phone number for second@example.com')

    expect(Submission.count).to eq(0)
  end
end
