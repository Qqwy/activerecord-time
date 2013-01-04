class TimeOfDay
  yaml_as "tag:yaml.org,2002:timestamp#hms"
  yaml_as "tag:yaml.org,2002:time"
  yaml_as "tag:ruby.yaml.org,2002:time"

  attr_accessor :hour # 0 - 23
  attr_accessor :minute # 0 - 59
  attr_accessor :second # 0 - 59

  def initialize(hour, minute, second = 0)
    raise "Invalid hour: #{hour}" unless hour >= 0 && hour <= 23
    raise "Invalid minute: #{minute}" unless minute >= 0 && minute <= 59
    raise "Invalid second: #{second}" unless second >= 0 && hour <= 59
    @hour, @minute, @second = hour, minute, second
  end

  def init_with(coder)
    parts = self.class.parse_parts(coder.scalar)
    initialize(*parts)
  end

  def self.now
    Time.now.time_of_day
  end

  def self.parse(string)
    return nil if string.blank?
    self.new(*parse_parts(string))
  end

  def self.parse_parts(string)
    string.strip!
    raise "Illegal time format: '#{string}'" unless string =~ /^(\d{1,2}):?(\d{2})?(?::(\d{1,2}))?$/
    [$1.to_i, $2.to_i, $3.to_i]
  end

  def on(date)
    Time.local(date.year, date.month, date.day, hour, minute, second)
  end

  def -(seconds)
    raise "Illegal argument: #{seconds.inspect}" unless seconds.is_a? Numeric
    t = Time.local(0, 1, 1, hour, minute, second)
    t -= seconds
    self.class.new(t.hour, t.min, t.sec)
  end

  def <=>(other)
    [@hour, @minute, @second] <=> [other.hour, other.minute, other.second]
  end

  def ==(other)
    return false unless other.is_a? TimeOfDay
    (self <=> other) == 0
  end

  def <(other)
    return false unless other.is_a? TimeOfDay
    (self <=> other) < 0
  end

  def <=(other)
    return false unless other.is_a? TimeOfDay
    (self <=> other) <= 0
  end

  def >(other)
    return false unless other.is_a? TimeOfDay
    (self <=> other) > 0
  end

  def >=(other)
    return false unless other.is_a? TimeOfDay
    (self <=> other) >= 0
  end

  def strftime(format)
    on(Date.today).strftime(format)
  end

  def to_s(with_seconds = true)
    if with_seconds
      "%02d:%02d:%02d" % [@hour, @minute, @second]
    else
      "%02d:%02d" % [@hour, @minute]
    end
  end

  def self.yaml_new(klass, tag, val)
    if String === val
      self.parse val
    else
      raise YAML::TypeError, "Invalid Time: " + val.inspect
    end
  end

  def to_yaml(opts = {})
    YAML::quick_emit(nil, opts) do |out|
      out.scalar('tag:yaml.org,2002:time', self.to_s, :plain)
    end
  end

end

class Time
  def time_of_day
    TimeOfDay.new(hour, min, sec)
  end

end

class Date
  def at(time_of_day)
    Time.local(year, month, day, time_of_day.hour, time_of_day.minute, time_of_day.second)
  end

end
