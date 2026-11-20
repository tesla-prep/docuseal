# frozen_string_literal: true

# CIRQLE: sign-in through Keycloak (OpenID Connect). On when OIDC_ISSUER is set; password sign-in is then off.
if ENV['OIDC_ISSUER'].present?
  Devise.setup do |config|
    config.params_authenticatable = false
    config.omniauth :openid_connect,
                    issuer: ENV.fetch('OIDC_ISSUER'),
                    discovery: true,
                    scope: %i[openid email profile],
                    response_type: :code,
                    pkce: true,
                    client_options: {
                      identifier: ENV.fetch('OIDC_CLIENT_ID'),
                      secret: ENV.fetch('OIDC_CLIENT_SECRET'),
                      redirect_uri: "https://#{ENV.fetch('HOST')}/auth/openid_connect/callback"
                    }
  end
end
