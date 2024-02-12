class RecurringTodo < ActiveRecord::Base
  
  belongs_to :context
  belongs_to :project
  belongs_to :user

  attr_protected :user

  acts_as_state_machine :initial => :active, :column => 'state'
  
  state :active, :enter => Proc.new { |t| 
    t[:show_from], t.completed_at = nil, nil 
    t.occurences_count = 0
  }
  state :completed, :enter => Proc.new { |t| t.completed_at = Time.now.utc }, :exit => Proc.new { |t| t.completed_at = nil }
  
  validates_presence_of :description
  validates_length_of :description, :maximum => 100
  validates_length_of :notes, :maximum => 60000, :allow_nil => true 

  validates_presence_of :context

  event :complete do
    transitions :to => :completed, :from => [:active]
  end
  
  event :activate do
    transitions :to => :active, :from => [:completed]
  end
  
  # the following recurrence patterns can be stored:
  # 
  # daily todos - recurrence_period = 'daily'
  #   every nth day - nth stored in every_other1
  #   every work day - only_work_days = true
  #   tracks will choose between both options using only_work_days
  # weekly todos - recurrence_period = 'weekly'
  #   every nth week on a specific day -
  #      nth stored in every_other1 and the specific day is stored in every_day
  # monthly todos - recurrence_period = 'monthly'
  #   every day x of nth month - x stored in every_other1 and nth is stored in every_other2
  #   the xth y-day of every nth month (the forth tuesday of every 2 months) -
  #      x stored in every_other3, y stored in every_count, nth stored in every_other2
  #   choosing between both options is done on recurrence_selector where 0 is
  #   for first type and 1 for second type
  # yearly todos - recurrence_period = 'yearly'
  #   every day x of month y - x is stored in every_other1, y is stored in every_other2
  #   the x-th day y of month z (the forth tuesday of september) -
  #     x is stored in every_other3, y is stored in every_count, z is stored in every_other2
  #   choosing between both options is done on recurrence_selector where 0 is
  #   for first type and 1 for second type
  
  # DAILY
  
  def daily_selector=(selector)
    case selector
    when 'daily_every_x_day'
      self.only_work_days = false
    when 'daily_every_work_day'
      self.only_work_days = true
    else
      raise Exception.new, "unknown daily recurrence pattern: '#{selector}'"      
    end
  end
  
  def daily_every_x_days=(x)
    if recurring_period=='daily'
      self.every_other1 = x
    end
  end
  
  def daily_every_x_days
    return self.every_other1
  end
  
  # WEEKLY
  
  def weekly_every_x_week=(x)
    self.every_other1 = x if recurring_period=='weekly'
  end
  
  def weekly_every_x_week
    return self.every_other1
  end
  
  def switch_week_day (day, position)
    if self.every_day.nil?
      self.every_day='       '
    end
    self.every_day = self.every_day[0,position] + day + self.every_day[position+1,self.every_day.length]
  end
  
  def weekly_return_monday=(selector)
    switch_week_day(selector,1) if recurring_period=='weekly'
  end

  def weekly_return_tuesday=(selector)
    switch_week_day(selector,2) if recurring_period=='weekly'
  end
  
  def weekly_return_wednesday=(selector)
    switch_week_day(selector,3) if recurring_period=='weekly'
  end
  
  def weekly_return_thursday=(selector)
    switch_week_day(selector,4) if recurring_period=='weekly'
  end
  
  def weekly_return_friday=(selector)
    switch_week_day(selector,5) if recurring_period=='weekly'
  end

  def weekly_return_saturday=(selector)
    switch_week_day(selector,6) if recurring_period=='weekly'
  end
  
  def weekly_return_sunday=(selector)
    switch_week_day(selector,0) if recurring_period=='weekly'
  end
  
  def on_xday(n)
    unless self.every_day.nil?
      return self.every_day[n,1] == ' ' ? false : true
    else
      return false
    end
  end
  
  def on_monday
    return on_xday(1)
  end
  
  def on_tuesday
    return on_xday(2)
  end
  
  def on_wednesday
    return on_xday(3)
  end
  
  def on_thursday
    return on_xday(4)
  end
  
  def on_friday
    return on_xday(5)
  end
  
  def on_saturday
    return on_xday(6)
  end
  
  def on_sunday
    return on_xday(0)
  end

  # MONTHLY
  
  def monthly_selector=(selector)
    if recurring_period=='monthly'
      self.recurrence_selector= (selector=='monthly_every_x_day')? 0 : 1
    end
  end
  
  def monthly_every_x_day=(x)
    self.every_other1 = x if recurring_period=='monthly'
  end
  
  def monthly_every_x_day
    return self.every_other1
  end
  
  def is_monthly_every_x_day
    return self.recurrence_selector == 0 if recurring_period == 'monthly'
    return false
  end

  def is_monthly_every_xth_day
    return self.recurrence_selector == 1 if recurring_period == 'monthly'
    return false
  end
  
  def monthly_every_x_month=(x)
    self.every_other2 = x if recurring_period=='monthly' && recurrence_selector == 0
  end
  
  def monthly_every_x_month
    # in case monthly pattern is every day x, return every_other2 otherwise
    # return a default value
    if self.recurrence_selector == 0
      return self.every_other2
    else
      return 1
    end
  end

  def monthly_every_x_month2=(x)    
    self.every_other2 = x if recurring_period=='monthly' && recurrence_selector == 1
  end

  def monthly_every_x_month2
    # in case monthly pattern is every xth day, return every_other2 otherwise
    # return a default value
    if self.recurrence_selector == 1
      return self.every_other2
    else
      return 1
    end
  end
  
  def monthly_every_xth_day=(x)
    self.every_other3 = x if recurring_period=='monthly' 
  end
  
  def monthly_every_xth_day(default=nil)
    return self.every_other3 unless self.every_other3.nil?
    return default
  end
  
  def monthly_day_of_week=(dow)
    self.every_count = dow if recurring_period=='monthly'
  end
  
  def monthly_day_of_week
    return self.every_count
  end
  
  # YEARLY
  
  def yearly_selector=(selector)
    if recurring_period=='yearly'
      self.recurrence_selector = (selector=='yearly_every_x_day') ? 0 : 1
    end
  end
  
  def yearly_month_of_year=(moy)
    self.every_other2 = moy if self.recurring_period=='yearly'  && self.recurrence_selector == 0
  end
  
  def yearly_month_of_year
    # if recurrence pattern is every x day in a month, return month otherwise
    # return a default value
    if self.recurrence_selector == 0
      return self.every_other2
    else
      return Time.now.month
    end
  end

  def yearly_month_of_year2=(moy)
    self.every_other2 = moy if self.recurring_period=='yearly' && self.recurrence_selector == 1
  end
  
  def yearly_month_of_year2
    # if recurrence pattern is every xth day in a month, return month otherwise
    # return a default value
    if self.recurrence_selector == 1
      return self.every_other2
    else
      return Time.now.month
    end
  end
  
  def yearly_every_x_day=(x)
    self.every_other1 = x if recurring_period=='yearly'
  end
  
  def yearly_every_x_day
    return self.every_other1
  end
  
  def yearly_every_xth_day=(x)
    self.every_other3 = x if recurring_period=='yearly'
  end
  
  def yearly_every_xth_day
    return self.every_other3
  end
  
  def yearly_day_of_week=(dow)
    self.every_count=dow if recurring_period=='yearly'
  end
  
  def yearly_day_of_week
    return self.every_count
  end
  
  # target
  
  def recurring_target=(t)
    self.target = t
  end
  
  def recurring_show_days_before=(days)
    self.show_from_delta=days
  end
  
  def recurrence_pattern
    case recurring_period
    when 'daily'
      if only_work_days
        return "on work days"
      else
        if every_other1 > 1
          return "every #{every_other1} days"
        else
          return "every day"
        end
      end
    when 'weekly'
      if every_other1 > 1
        return "every #{every_other1} weeks"
      else
        return 'weekly'
      end
    when 'monthly'
      if self.recurrence_selector == 0
        return "every #{self.every_other2} month#{self.every_other2>1?'s':''} on day #{self.every_other1}"
      else
        return "every #{self.xth} #{self.day_of_week} of every #{self.every_other2} month#{self.every_other2>1?'s':''}"
      end
    when 'yearly'
      if self.recurrence_selector == 0
        return "every year on #{self.month_of_year} #{self.every_other1}"
      else
        return "every year on the #{self.xth} #{self.day_of_week} of #{self.month_of_year}"
      end
    else
      return 'unknown recurrence pattern: period unknown'
    end
  end  
  
  def xth
    xth_day = ['first','second','third','fourth','last']
    return self.every_other3.nil? ? '??' : xth_day[self.every_other3-1]
  end
  
  def day_of_week
    days_of_week = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
    return (self.every_count.nil? ? '??' : days_of_week[self.every_count])
  end
  
  def month_of_year
    months_of_year = ['January','Februari','March','April','May','June','July','August','September','October','November','December']
    return self.every_other2.nil? ? '??' : months_of_year[self.every_other2-1]
  end
  
  def starred?
    tags.any? {|tag| tag.name == Todo::STARRED_TAG_NAME}
  end
  
  def get_due_date(previous)
    case self.target
    when 'due_date'
      return get_next_date(previous)
    when 'show_from'
      # so leave due date empty
      return nil
    end
  end
  
  def get_show_from_date(previous)
    case self.target 
    when 'due_date'
      # so set show from date relative to due date unless show_from_delta is
      # zero / nil
      return (self.show_from_delta == 0 || self.show_from_delta.nil?) ? nil : get_due_date(previous) - self.show_from_delta.days
    when 'show_from_date'
      # Leave due date empty
      return get_next_date(previous)
    else
      raise Exception.new, "unexpected value of recurrence target '#{self.target}'"
    end
  end
  
  def get_next_date(previous)
    case self.recurring_period
    when 'daily' 
      return get_daily_date(previous)
    when 'weekly' 
      return get_weekly_date(previous)
    when 'monthly' 
      return get_monthly_date(previous)
    when 'yearly'
      return get_yearly_date(previous)
    else
      raise Exception.new, "unknown recurrence pattern: '#{self.recurring_period}'"
    end    
  end
  
  def get_daily_date(previous)
    # previous is the due date of the previous todo or it is the completed_at
    # date when the completed_at date is after due_date (i.e. you did not make
    # the due date in time)
    # 
    # assumes self.recurring_period == 'daily'
    if previous.nil?
      start = self.start_from.nil? ? Time.now.utc : self.start_from
    else
      # use the next day
      start = previous + 1.day
    end

    if self.only_work_days
      if start.wday() >= 1 && start.wday() <= 5  # 1=monday; 5=friday
        return start
      else
        if start.wday() == 0 # sunday
          return start + 1.day
        else # saturday
          return start + 2.day
        end
      end
    else # every nth day; n = every_other1
      # if there was no previous todo, do not add n: the first todo starts on
      # today or on start_from
      return previous == nil ? start : start+every_other1.day-1.day
    end
  end
  
  def get_weekly_date(previous)
    if previous == nil
      start = self.start_from.nil? ? Time.now.utc : self.start_from
    else
      start = previous + 1.day
      if start.wday() == 0 
        # we went to a new week , go to the nth next week and find first match
        # that week
        start += self.every_other1.week
      end
    end
    # check if there are any days left this week for the next todo
    start.wday().upto 6 do |i|
      return start + (i-start.wday()).days unless self.every_day[i,1] == ' '
    end
    
    # we did not find anything this week, so check the nth next, starting from
    # sunday
    start = start + self.every_other1.week - (start.wday()).days

    # check if there are any days left this week for the next todo
    start.wday().upto 6 do |i|
      return start + (i-start.wday()).days unless self.every_day[i,1] == ' '
    end

    raise Exception.new, "unable to find next weekly date (#{self.every_day})"    
  end
  
  def get_monthly_date(previous)
    if previous.nil?
      start = self.start_from.nil? ? Time.now.utc : self.start_from
    else
      start = previous
    end
    day = self.every_other1
    n = self.every_other2
    
    case self.recurrence_selector
    when 0 # specific day of the month
      if start.mday >= day  
        # there is no next day n in this month, search in next month
        start += n.months
        # go back to day
      end
      return Time.utc(start.year, start.month, day)
      
    when 1 # relative weekday of a month
      the_next = get_xth_day_of_month(self.every_other3, self.every_count, start.month, start.year)
      if the_next.nil? || the_next <= start
        # the nth day is already passed in this month, go to next month and try
        # again
        the_next = the_next+n.months
        # TODO: if there is still no match, start will be set to nil. if we ever
        # support 5th day of the month, we need to handle this case
        the_next = get_xth_day_of_month(self.every_other3, self.every_count, the_next.month, the_next.year)
      end
      return the_next
    else
      raise Exception.new, "unknown monthly recurrence selection (#{self.recurrence_selector})"    
    end
    return nil
  end
  
  def get_xth_day_of_month(x, weekday, month, year)
    if x == 5
      # last -> count backwards
      last_day = Time.utc(year, month, Time.days_in_month(month))
      while last_day.wday != weekday
        last_day -= 1.day
      end
      return last_day
    else
      # 1-4th -> count upwards
      start = Time.utc(year,month,1)
      n = x
      while n > 0
        while start.wday() != weekday
          start+= 1.day
        end
        n -= 1
        start += 1.day unless n==0 
      end
      return start
    end
  end
  
  def get_yearly_date(previous)
    if previous.nil?
      start = self.start_from.nil? ? Time.now.utc : self.start_from
    else
      start = previous
    end

    day = self.every_other1
    month = self.every_other2
    
    case self.recurrence_selector
    when 0 # specific day of a specific month
      # if there is no next month n in this year, search in next year
      if start.month >= month
        start = Time.utc(start.year+1, month, 1) if start.day >= day
        start = Time.utc(start.year, month, 1) if start.day <= day
      end
      return Time.utc(start.year, month, day)
      
    when 1 # relative weekday of a specific month
      # if there is no next month n in this year, search in next year
      the_next = start.month > month ? Time.utc(start.year+1, month, 1) : start
      
      # get the xth day of the month
      the_next = get_xth_day_of_month(self.every_other3, self.every_count, month, the_next.year)
      
      # if the_next is before previous, we went back into the past, so try next
      # year
      the_next = get_xth_day_of_month(self.every_other3, self.every_count, month, start.year+1) if the_next <= start
      
      return the_next
    else
      raise Exception.new, "unknown monthly recurrence selection (#{self.recurrence_selector})"    
    end
    return nil
  end
  
  def has_next_todo(previous)
    unless self.number_of_occurences.nil?
      return self.occurences_count < self.number_of_occurences
    else
      if self.end_date.nil?
        return true
      else
        case self.target
        when 'due_date'
          return get_due_date(previous) <= self.end_date
        when 'show_from_date'
          return get_show_from_date(previous) <= self.end_date
        else
          raise Exception.new, "unexpected value of recurrence target '#{self.target}'"
        end
      end
    end
  end
  
  def toggle_completion!
    saved = false
    if completed?
      saved = activate!
    else
      saved = complete!
    end
    return saved
  end
  
  def toggle_star!
    if starred?
      delete_tags Todo::STARRED_TAG_NAME
      tags.reload
    else
      add_tag Todo::STARRED_TAG_NAME
      tags.reload
    end 
    starred?  
  end
  
  def inc_occurences
    self.occurences_count += 1
    self.save
  end
  
  protected
  
  def validate
    errors.add("", "At least one day must be selected in the weekly pattern") if self.every_day == '       '
  end
  
end
