# frozen_string_literal: true

class SendSubmitterInvitationSmsJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    return if submitter.phone.blank? || !TwilioSms.configured?
    return if submitter.completed_at? || submitter.declined_at?
    return if submitter.submission.archived_at? || submitter.submission.expired?
    return if submitter.template&.archived_at?

    TwilioSms.deliver(submitter.phone, build_body(submitter))

    SubmissionEvent.create!(submitter:, event_type: 'send_sms', data: { phone: submitter.phone })

    submitter.sent_at ||= Time.current
    submitter.save!
  end

  private

  def build_body(submitter)
    key = submitter.viewer? ? 'submitter_invitation_sms_body_view' : 'submitter_invitation_sms_body_sign'
    link = Rails.application.routes.url_helpers.submit_form_url(slug: submitter.slug, **Docuseal.default_url_options)

    I18n.with_locale(submitter.account.locale) { I18n.t(key) }
        .sub('{account.name}', submitter.account.name)
        .sub('{submitter.link}', link)
  end
end
