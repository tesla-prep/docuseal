# frozen_string_literal: true

RSpec.describe 'Notifications Settings' do
  let(:user) { create(:user, account: create(:account)) }

  before do
    sign_in(user)
  end

  it 'shows the notifications settings page' do
    visit settings_notifications_path

    expect(page).to have_content('Email Notifications')
    expect(page).to have_content('Receive notification emails on completed submission')
    expect(page).to have_content('Sign Request Email Reminders')

    expect(page).to have_field('account_config[value]')
    expect(page).to have_field('user_config[value]')
    %w[first_duration second_duration third_duration].each do |duration|
      expect(page).to have_field("account_config[value][#{duration}]")
    end
  end

  context 'when changes email notifications settings' do
    it 'updates BCC email address' do
      visit settings_notifications_path

      fill_in 'account_config[value]', with: 'john.doe@example.com'

      all(:button, 'Save')[0].click

      expect(page).to have_content('Changes have been saved')

      account_config = AccountConfig.find_by(account: user.account, key: AccountConfig::BCC_EMAILS)

      expect(account_config.value).to eq('john.doe@example.com')
    end

    it 'delete BCC email address' do
      create(:account_config, account: user.account, key: AccountConfig::BCC_EMAILS, value: 'john.doe.bbc@example.com')

      visit settings_notifications_path

      expect(page).to have_field('account_config[value]', with: 'john.doe.bbc@example.com')

      fill_in 'account_config[value]', with: ''

      all(:button, 'Save')[0].click

      expect(page).to have_content('Changes have been saved')
    end

    it 'disable receive notification emails on completed submission' do
      visit settings_notifications_path

      uncheck 'user_config[value]'

      expect(UserConfig.find_by(user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL).value).to be false
    end

    it 'enable receive notification emails on completed submission' do
      create(:user_config, user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL, value: false)

      visit settings_notifications_path

      check 'user_config[value]'

      expect(UserConfig.find_by(user:, key: UserConfig::RECEIVE_COMPLETED_EMAIL).value).to be true
    end
  end

  context 'when changes sign request email reminders settings' do
    it 'updates first reminder duration' do
      visit settings_notifications_path

      selected_values = %w[first_duration second_duration third_duration].index_with do |_|
        AccountConfigs::REMINDER_DURATIONS.keys.sample
      end

      selected_values.each do |duration, value|
        selected_duration_name = AccountConfigs::REMINDER_DURATIONS[value]
        select selected_duration_name, from: "account_config[value][#{duration}]"
      end

      expect do
        all(:button, 'Save')[1].click
      end.to change(AccountConfig, :count).by(1)

      account_config = AccountConfig.find_by(account: user.account, key: AccountConfig::SUBMITTER_REMINDERS)

      expect(page).to have_content('Changes have been saved')

      selected_values.each do |duration, value|
        expect(account_config.value[duration]).to eq(value)
      end
    end
  end

  context 'when sign request email reminders are due' do
    let(:template) { create(:template, account: user.account, author: user, submitter_count: 2) }
    let(:submission) do
      create(:submission, :with_submitters, template:, created_by_user: user, submitters_order: 'preserved')
    end
    let(:first_submitter) { submission.submitters.find_by(uuid: template.submitters.first['uuid']) }
    let(:second_submitter) { submission.submitters.find_by(uuid: template.submitters.second['uuid']) }

    before do
      allow(Sidekiq).to receive(:redis).and_return('OK')
      create(:account_config, account: user.account, key: AccountConfig::SUBMITTER_REMINDERS,
                              value: { 'first_duration' => 'one_hour', 'second_duration' => 'two_days' })
      create(:account_config, account: user.account, key: AccountConfig::ENFORCE_SIGNING_ORDER_KEY, value: true)
      submission.submitters.each { |submitter| submitter.update!(sent_at: 2.hours.ago) }
    end

    it 'sends one reminder to the signer whose turn it is' do
      expect { SendSubmitterRemindersJob.new.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(ActionMailer::Base.deliveries.last.to).to eq([first_submitter.email])
      expect(first_submitter.submission_events.where(event_type: 'send_reminder_email').count).to eq(1)
      expect(second_submitter.submission_events.count).to eq(0)

      expect { SendSubmitterRemindersJob.new.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end

    it 'counts every reminder from the invitation' do
      first_submitter.update!(sent_at: 60.hours.ago)
      create(:submission_event, submission:, submitter: first_submitter, event_type: 'send_reminder_email',
                                event_timestamp: 1.day.ago)

      expect { SendSubmitterRemindersJob.new.perform }.to change(ActionMailer::Base.deliveries, :count).by(1)
      expect(first_submitter.submission_events.where(event_type: 'send_reminder_email').count).to eq(2)
    end

    it 'skips signers who completed or declined' do
      first_submitter.update!(declined_at: Time.current)
      second_submitter.update!(completed_at: Time.current)

      expect { SendSubmitterRemindersJob.new.perform }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
