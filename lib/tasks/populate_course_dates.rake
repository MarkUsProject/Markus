namespace :db do
  desc 'Populate courses.start_at and courses.end_at based on naming patterns'
  task populate_course_dates: :environment do
    PopulateCourseDates.run(dry_run: ENV['DRY_RUN'] == '1')
  end
end

module PopulateCourseDates
  DEMO_OR_SANDBOX = /demo|sandbox/i
  YEAR_MONTH_IN_NAME = /-(\d{4})-(01|05|09)\b/
  UOFT_SESSION_CODE = /(?<!\d)(\d{4})([159])(?!\d)/
  YEAR_LONG = /H1Y/i

  module_function

  def run(dry_run: false)
    tally = Hash.new(0)
    candidates = Course.where(start_at: nil).or(Course.where(end_at: nil))
    puts "[populate_course_dates] #{'DRY-RUN — ' if dry_run}scanning #{candidates.count} candidates"

    candidates.find_each do |course|
      action, detail = process(course, dry_run: dry_run)
      tally[action] += 1
      puts format('  [%<action>-20s] %<name>-32s %<detail>s', action: action, name: course.name, detail: detail)
    end

    puts '[populate_course_dates] tally:'
    tally.sort.each { |k, v| puts "  #{k}: #{v}" }
  end

  def process(course, dry_run:)
    return [:skipped_demo_sandbox, ''] if demo_or_sandbox?(course)

    parsed = parse(course)
    return [:skipped_unparseable, "name=#{course.name.inspect} display=#{course.display_name.inspect}"] if parsed.nil?

    start_at, end_at = parsed
    apply(course, start_at, end_at, dry_run: dry_run)
  end

  def demo_or_sandbox?(course)
    "#{course.name} #{course.display_name}" =~ DEMO_OR_SANDBOX
  end

  def parse(course)
    bucket, year = bucket_and_year(course)
    return if bucket.nil?

    year_long = course.name.to_s.match?(YEAR_LONG)
    range_for(bucket, year, year_long: year_long)
  end

  def bucket_and_year(course)
    if (m = course.name.to_s.match(YEAR_MONTH_IN_NAME))
      [m[2], m[1].to_i]
    elsif (m = (course.name.to_s + ' ' + course.display_name.to_s).match(UOFT_SESSION_CODE))
      [format('%02d', m[2].to_i), m[1].to_i]
    end
  end

  def range_for(bucket, year, year_long:)
    case bucket
    when '01'
      start_year = year_long ? year - 1 : year
      [start_of(start_year, year_long ? 9 : 1), end_of(year, 4)]
    when '05'
      [start_of(year, 5), end_of(year, 8)]
    when '09'
      end_year = year_long ? year + 1 : year
      [start_of(year, 9), end_of(end_year, year_long ? 4 : 12)]
    end
  end

  def start_of(year, month)
    Time.zone.local(year, month, 1, 0, 0, 0)
  end

  def end_of(year, month)
    Time.zone.local(year, month, 1).end_of_month.change(hour: 23, min: 59, sec: 59)
  end

  def apply(course, start_at, end_at, dry_run:)
    new_start = course.start_at || start_at
    new_end = course.end_at || end_at
    return [:skipped_already_set, ''] if course.start_at && course.end_at

    detail = "start=#{new_start.to_date} end=#{new_end.to_date}"
    return [:would_update, detail] if dry_run

    course.update(start_at: new_start, end_at: new_end)
    return [:invalid, course.errors.full_messages.join('; ')] if course.errors.any?

    [:updated, detail]
  end
end
