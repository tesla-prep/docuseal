# frozen_string_literal: true

class SendSubmitterRemindersJob
  include Sidekiq::Job

  sidekiq_options queue: :recurrent, retry: false

  INTERVAL = 10.minutes

  def perform
    lock_seconds = (INTERVAL - 1.minute).to_i

    return unless Sidekiq.redis { |conn| conn.call('SET', 'submitter_reminders_lock', '1', 'NX', 'EX', lock_seconds) }

    SendSubmitterRemindersJob.perform_in(INTERVAL)

    AccountConfig.where(key: AccountConfig::SUBMITTER_REMINDERS).find_each do |config|
      durations = config.value.to_h.values_at('first_duration', 'second_duration', 'third_duration')
                        .filter_map { |key| AccountConfigs::REMINDER_DURATIONS[key] }
                        .map { |value| value.split.then { |count, unit| count.to_i.public_send(unit) } }

      next if durations.empty?

      Submitter.joins(:submission)
               .where(account_id: config.account_id, completed_at: nil, declined_at: nil,
                      submissions: { archived_at: nil })
               .where(sent_at: (Time.current - durations.sum - 1.day)..)
               .where.not(email: [nil, ''])
               .find_each { |submitter| remind(submitter, durations) }
    end
  end

  private

  def remind(submitter, durations)
    reminders = submitter.submission_events.where(event_type: 'send_reminder_email')
    count = reminders.count

    return if count >= durations.size
    return if (reminders.maximum(:event_timestamp) || submitter.sent_at) + durations[count] > Time.current
    return if submitter.viewer?
    return if submitter.preferences['send_email'] == false
    return if submitter.submission.expired?
    return if submitter.template&.archived_at?
    return unless Submitters::AuthorizedForForm.pass_submitters_order?(submitter)

    mail = SubmitterMailer.invitation_reminder_email(submitter)

    Submitters::ValidateSending.call(submitter, mail)

    mail.deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_reminder_email')
  rescue StandardError => e
    Rails.logger.error("Submitter reminder #{submitter.id} failed: #{e.message}")
  end
end
