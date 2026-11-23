# frozen_string_literal: true

RSpec.describe 'Sign In' do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account:, email: 'john.dou@example.com', password: 'strong_password') }

  before do
    visit new_user_session_path
  end

  it 'opens the sign-in page instead of the landing page at the root when signed out' do
    visit root_path

    expect(page).to have_current_path(new_user_session_path)
    expect(page).not_to have_content('Run on your own host')
  end

  context 'when only with email and password' do
    it 'signs in successfully with valid email and password' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it "doesn't sign in if the email or password are incorrect" do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'wrong_password'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end

  context 'when 2FA is required' do
    before do
      user.update(otp_required_for_login: true, otp_secret: User.generate_otp_secret)
    end

    it 'signs in successfully with valid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: user.current_otp
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it 'fails to sign in with invalid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: '123456'
      click_button 'Sign In'

      expect(page).to have_content('Invalid email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end

  context 'when sign-in goes through OIDC' do
    def enable_oidc
      allow(Devise).to receive(:omniauth_configs).and_return(oidc: Object.new)
    end

    it "doesn't sign in with a valid email and password" do
      enable_oidc
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      visit root_path

      expect(page).not_to have_content('Document Templates')
      expect(user.reload.sign_in_count).to eq(0)
    end

    it "doesn't sign in through a password reset link" do
      visit edit_user_password_path(reset_password_token: user.send(:set_reset_password_token))
      enable_oidc
      fill_in 'New password', with: 'new_strong_password'
      fill_in 'Confirm new password', with: 'new_strong_password'
      click_button 'Change my password'
      visit root_path

      expect(page).not_to have_content('Document Templates')
      expect(user.reload.sign_in_count).to eq(0)
    end

    it "doesn't sign in through an invitation link" do
      visit invitation_path(reset_password_token: user.send(:set_reset_password_token))
      enable_oidc
      fill_in 'Set password', with: 'new_strong_password'
      fill_in 'Confirm new password', with: 'new_strong_password'
      click_button 'Save password and Sign in'
      visit root_path

      expect(page).not_to have_content('Document Templates')
      expect(user.reload.sign_in_count).to eq(0)
    end
  end
end
