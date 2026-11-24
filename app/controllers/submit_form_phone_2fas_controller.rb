# frozen_string_literal: true

class SubmitFormPhone2fasController < ApplicationController
  OTP_PURPOSE = 'form_phone_2fa'

  around_action :with_browser_locale

  skip_before_action :authenticate_user!
  skip_authorization_check

  before_action :load_submitter

  def create
    RateLimit.call("verify-phone-2fa-code-#{@submitter.id}", limit: 2, ttl: 45.seconds, enabled: true)

    if OtpChallenges.verify(params[:one_time_code].to_s.gsub(/\D/, ''), otp_value, purpose: OTP_PURPOSE)
      SubmissionEvents.create_with_tracking_data(@submitter, 'phone_verified', request, { phone: @submitter.phone })

      cookies.encrypted[:phone_2fa_slug] =
        { value: @submitter.slug, expires: Submitters::StartForm::COOKIES_TTL.from_now,
          **Submitters::StartForm::COOKIES_DEFAULTS }

      redirect_to submit_form_path(@submitter.slug, lang:)
    else
      redirect_with_error(I18n.t(:invalid_code))
    end
  rescue RateLimit::LimitApproached
    redirect_with_error(I18n.t(:too_many_attempts))
  end

  def update
    return redirect_with_error(I18n.t(:sms_not_configured)) unless TwilioSms.configured?

    if @submitter.submission_events.where(event_type: 'send_2fa_sms').exists?(created_at: 15.seconds.ago..)
      return redirect_with_error(I18n.t(:rate_limit_exceeded))
    end

    RateLimit.call("send-phone-code-#{@submitter.id}", limit: 2, ttl: 45.seconds, enabled: true)

    code = OtpChallenges.generate(otp_value, purpose: OTP_PURPOSE)

    TwilioSms.deliver(@submitter.phone, I18n.t(:verification_code_sms_body).sub('{code}', code))

    SubmissionEvent.create!(submitter: @submitter, event_type: 'send_2fa_sms', data: { phone: @submitter.phone })

    redir_params = params[:resend] ? { alert: I18n.t(:code_has_been_resent) } : {}

    redirect_to submit_form_path(@submitter.slug, status: :sent, lang:), **redir_params
  rescue RateLimit::LimitApproached
    redirect_with_error(I18n.t(:too_many_attempts))
  rescue TwilioSms::Error => e
    Rails.logger.error("Phone 2FA SMS for submitter #{@submitter.id} failed: #{e.message}")

    redirect_with_error(I18n.t(:invalid_phone_number))
  end

  private

  def redirect_with_error(alert)
    redirect_to submit_form_path(@submitter.slug, status: :error, lang:), alert:
  end

  def load_submitter
    @submitter = Submitter.find_by!(slug: params[:submitter_slug])
  end

  def otp_value
    [@submitter.phone, @submitter.slug].join(':')
  end

  def lang
    params[:lang].presence
  end
end
