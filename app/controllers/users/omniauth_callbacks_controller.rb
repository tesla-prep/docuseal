# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def openid_connect
      info = request.env['omniauth.auth'].info
      email = info.email.to_s.downcase

      user = User.find_by(email:) ||
             User.create!(account: Account.order(:id).first, email:, first_name: info.first_name,
                          last_name: info.last_name, password: SecureRandom.base58(32))

      unless user.active_for_authentication?
        return redirect_to new_user_session_path,
                           alert: 'Your DocuSeal account is archived. Ask an administrator to restore it.'
      end

      sign_in_and_redirect user, event: :authentication
    end
  end
end
