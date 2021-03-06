class Task < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :user
  has_many :active_dates, dependent: :destroy
  acts_as_taggable

  validates_presence_of :name, :start_date, :end_date
  validates_length_of :name, maximum: 50
  validates_uniqueness_of :name, scope: :user_id

  validates_date :start_date, :on_or_after => :today,
                              :on_or_after_message => "can't be in the past"

  validates_date :end_date, :on_or_after => :start_date, :on_or_before => lambda { 5.years.since },
                               :on_or_after_message => "can't be before the start date",
                               :on_or_before_message => "can only be a maximum of 5 years in the future"


  def active?
    !end_date || end_date > Date.today
  end

  def active_day?(date)
    send(date.strftime("%A").downcase)
  end

  def days_complete
    active_dates.where(completed: true).count
  end

  def days_missed
    active_dates.where(completed: false).count
  end

  def days_remaining
    active_dates.where(completed: nil).count
  end

  def unmarked_days
    active_dates.where("completed IS ? AND task_date <= ?", nil, Date.today).count
  end

  def current_streak
    last_marked_date = active_dates.where.not(completed: nil).last
    return 0 if !last_marked_date || last_marked_date.completed == false
    dates = active_dates.where(completed: true).reverse
    dates.take_while { |date| date.completed }.size
  end

  def best_streak
    return 0 if !active_dates.where(completed: true).exists?
    completed_chunks = active_dates.all.chunk { |date| date.completed || nil }
    completed_chunks.map { |_, x| x.size }.max
  end

  def percent_complete_to_date
    comp, missed, unmarked = days_complete.to_f, days_missed.to_f, unmarked_days.to_f
    return number_to_percentage(0, precision: 2) if comp + missed + unmarked == 0.0
    number_to_percentage((comp / (comp + missed + unmarked)) * 100, precision: 2)
  end

  def percent_complete_overall
    comp, missed, unmarked, days = days_complete.to_f, days_missed.to_f, unmarked_days.to_f, days_remaining.to_f
    return number_to_percentage(0, precision: 2) if comp + missed + unmarked == 0
    number_to_percentage((comp / (comp + missed + unmarked + days)) * 100, precision: 2)
  end

end
