describe Task do
  subject { described_class.new }
  context '#active?' do
    it 'returns true if the task has no end date' do
      expect(subject.active?).to eq(true)
    end
    it 'returns true if the task end date is after today' do
      task = Task.new
      task.end_date = Date.parse("01/01/3017")
      expect(subject.active?).to eq(true)
    end
    it 'returns false if the task end date is before today' do
      task = Task.new
      task.end_date = Date.parse("01/01/2017")
      expect(subject.active?).to eq(true)
    end
  end
  context '#active_day?' do
    before do
      subject.start_date = Date.today
      subject.end_date = Date.parse("01/01/3017")
    end
    it 'returns true if the date is one of the chosen days of the week' do
      set_days(subject, true)
      expect(subject.active_day?(subject.start_date)).to eq true
    end
    it 'returns false if the date is not one of the chosen days of the week' do
      set_days(subject, false)
      expect(subject.active_day?(subject.start_date)).to eq false
    end
  end
  context '#days_complete, #days_missed, #days_remaining' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create_list(:task, 1, user: User.first)
      FactoryGirl.create_list(:active_date, 365, task: Task.first)
      active_date = Task.first.active_dates.first
      active_date.update(completed: false)
      active_date.save!
      active_date = Task.first.active_dates.second
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.third
      active_date.update(completed: true)
      active_date.save!
    end
    it '#days_complete returns the total number of days marked as complete' do
      expect(Task.first.days_complete).to eq 2
    end
    it '#days_missed returns the total number of days marked as missed' do
      expect(Task.first.days_missed).to eq 1
    end
    it '#days_remaining returns the total number of days remaining' do
      expect(Task.first.days_remaining).to eq 362
    end
  end
  context '#current_streak' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create_list(:task, 1, user: User.first)
      FactoryGirl.create_list(:active_date, 365, task: Task.first)
    end
    it 'should return zero if no dates have been marked missed or complete' do
      expect(Task.first.current_streak).to eq 0
    end
    it 'should return zero if the last date was marked missed' do
      active_date = Task.first.active_dates.second
      active_date.update(completed: false)
      active_date.save!
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.current_streak).to eq 0
    end
    it 'should return 2 if the last two consecutive dates were marked completed' do
      active_date = Task.first.active_dates.second
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.third
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.current_streak).to eq 2
    end
  end
  context '#best_streak' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create_list(:task, 1, user: User.first)
      FactoryGirl.create_list(:active_date, 365, task: Task.first)
    end
    it 'should return zero if no dates have ever been marked complete' do
      expect(Task.first.best_streak).to eq 0
    end
    it 'should return one when the best streak is one' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.second
      active_date.update(completed: false)
      active_date.save!
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.best_streak).to eq 1
    end
    it 'should return 2 when the best streak is two' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.second
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.third
      active_date.update(completed: false)
      active_date.save!
      active_date = Task.first.active_dates.fourth
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.best_streak).to eq 2
    end
  end
  context '#unmarked_days' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create(:task, name: Faker::Superhero.name, user: User.first)
      FactoryGirl.create_list(:active_date, 1, task: Task.first)
    end
    it 'should return one if one date (up to and including today\'s date) is unmarked' do
      expect(Task.first.unmarked_days).to eq 1
    end
    it 'should return zero if no date (up to and including today\'s date) is marked as completed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.unmarked_days).to eq 0
    end
    it 'should return zero if no date (up to and including today\'s date) is marked as missed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: false)
      active_date.save!
      expect(Task.first.unmarked_days).to eq 0
    end
  end
  context '#percent_complete_to_date' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create(:task, name: Faker::Superhero.name, user: User.first)
      FactoryGirl.create_list(:active_date, 2, task: Task.first)
    end
    it 'should return 0.00% if no dates have been marked either missed or completed' do
      expect(Task.first.percent_complete_to_date).to eq "0.00%"
    end
    it 'should return 0.00% if the only date has been marked missed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: false)
      active_date.save!
      expect(Task.first.percent_complete_to_date).to eq "0.00%"
    end
    it 'should return 100.00% if the only date has been marked completed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.percent_complete_to_date).to eq "100.00%"
    end
    it 'should return 50.00% if one of two dates was marked completed and the other missed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.second
      active_date.update(completed: false)
      active_date.save!
      expect(Task.first.percent_complete_to_date).to eq "50.00%"
    end
  end
  context '#percent_complete_overall' do
    before do
      FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
      FactoryGirl.create(:task, name: Faker::Superhero.name, user: User.first)
      FactoryGirl.create_list(:active_date, 10, task: Task.first)
    end
    it 'should return 0.00% if no dates have been marked either missed or completed' do
      expect(Task.first.percent_complete_overall).to eq "0.00%"
    end
    it 'should return 0.00% if one date of ten has been marked missed and none completed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: false)
      active_date.save!
      expect(Task.first.percent_complete_overall).to eq "0.00%"
    end
    it 'should return 10.00% if one date of ten has been marked completed and none missed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.percent_complete_overall).to eq "10.00%"
    end
    it 'should return 20.00% if two dates of ten has been marked completed and one missed' do
      active_date = Task.first.active_dates.first
      active_date.update(completed: true)
      active_date.save!
      active_date = Task.first.active_dates.second
      active_date.update(completed: false)
      active_date.save!
      active_date = Task.first.active_dates.third
      active_date.update(completed: true)
      active_date.save!
      expect(Task.first.percent_complete_overall).to eq "20.00%"
    end
  end
  # context '#total_days_complete' do
  #   before do
  #     arr = %w(first second third)
  #     FactoryGirl.create(:user, username: "Rob Brentnall", email: "test@test.com", password: "123456", password_confirmation: "123456")
  #     arr.size.times do |i|
  #       FactoryGirl.create(:task, name: Faker::Superhero.name, user: User.first)
  #       FactoryGirl.create_list(:active_date, 10, task: Task.send(arr[i]))
  #     end
  #   end
  #   it 'should return 0 if no dates have been marked either missed or completed on any task' do
  #     expect(Task.total_days_complete).to eq 0
  #   end
  #   it 'should return 3 if one date has been marked either completed on two different tasks' do
  #     arr = %w(first second third)
  #     arr.size.times do |i|
  #       active_date = Task.send(arr[i]).active_dates.first
  #       active_date.update(completed: true)
  #       active_date.save!
  #     end
  #     expect(Task.total_days_complete).to eq 3
  #   end
  # end
end
