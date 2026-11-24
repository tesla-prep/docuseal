# frozen_string_literal: true

module TwilioSms
  ENV_KEYS = %w[TWILIO_ACCOUNT_SID TWILIO_API_KEY_SID TWILIO_API_KEY_SECRET TWILIO_MESSAGING_SERVICE_SID].freeze

  Error = Class.new(StandardError)

  module_function

  def configured?
    ENV.values_at(*ENV_KEYS).all?(&:present?)
  end

  def deliver(to, body)
    credentials = "#{ENV.fetch('TWILIO_API_KEY_SID')}:#{ENV.fetch('TWILIO_API_KEY_SECRET')}"

    response = Faraday.post(
      "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch('TWILIO_ACCOUNT_SID')}/Messages.json",
      URI.encode_www_form(To: to, MessagingServiceSid: ENV.fetch('TWILIO_MESSAGING_SERVICE_SID'), Body: body),
      'Authorization' => "Basic #{Base64.strict_encode64(credentials)}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    )

    raise Error, "Twilio answered HTTP #{response.status}: #{response.body}" unless response.success?

    response
  end
end
