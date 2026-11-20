# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def openid_connect
      info = request.env['omniauth.auth'].info
      email = info.email.to_s.downcase

      user = User.find_by(email:) ||
             User.create!(account: Account.order(:id).first, email:, first_name: info.first_name,
                          last_name: info.last_name, password: SecureRandom.base58(32))

      sign_in_and_redirect user, event: :authentication
    end
  end
end
