require 'rails_helper'
require 'rake'

RSpec.describe 'db:populate_course_dates', type: :task do
  before do
    Rake.application.rake_require('tasks/populate_course_dates') unless Rake::Task.task_defined?('db:populate_course_dates')
    Rake::Task.define_task(:environment)
    task.reenable
  end

  let(:task) { Rake::Task['db:populate_course_dates'] }

  def make_course(name, display_name = nil, **attrs)
    create(:course, name: name, display_name: display_name || name, **attrs)
  end

  def expect_dates(course, start_date, end_date)
    course.reload
    expect(course.start_at.to_date.iso8601).to eq(start_date)
    expect(course.end_at.to_date.iso8601).to eq(end_date)
  end

  describe 'numeric name suffix (Pattern A)' do
    it 'parses Fall: csc110-2024-09 -> Sep 1 .. Dec 31 of the same year' do
      c = make_course('csc110-2024-09', 'Foundations of Computer Science I')
      task.invoke
      expect_dates(c, '2024-09-01', '2024-12-31')
    end

    it 'parses Winter: csc111-2026-01 -> Jan 1 .. Apr 30 of the same year' do
      c = make_course('csc111-2026-01', 'Foundations of Computer Science II')
      task.invoke
      expect_dates(c, '2026-01-01', '2026-04-30')
    end

    it 'parses Summer: csc384-2025-05 -> May 1 .. Aug 31 of the same year' do
      c = make_course('csc384-2025-05', 'Introduction to Artificial Intelligence')
      task.invoke
      expect_dates(c, '2025-05-01', '2025-08-31')
    end
  end

  describe 'UofT 5-digit session code (Pattern B)' do
    it 'reads the session from display_name when name has none' do
      c = make_course('CSC369H1-S', 'Operating Systems (20261)')
      task.invoke
      expect_dates(c, '2026-01-01', '2026-04-30')
    end

    it 'reads the session embedded in display_name with surrounding text' do
      c = make_course('JSC370H1-S-LEC0101', 'JSC370H1 S LEC0101 20261:Data Science II')
      task.invoke
      expect_dates(c, '2026-01-01', '2026-04-30')
    end

    it 'trusts the session code over the F/S/Y registrar suffix' do
      c = make_course('MRKUS100H-F-LEC0101-20251', 'MarkUs Jan 2025')
      task.invoke
      expect_dates(c, '2025-01-01', '2025-04-30')
    end
  end

  describe 'year-long courses (H1Y)' do
    it 'spans Sep (Y-1) -> Apr Y for a Winter session code' do
      c = make_course('CSC998H1Y-20251', 'CSC998H1Y 20251')
      task.invoke
      expect_dates(c, '2024-09-01', '2025-04-30')
    end

    it 'spans Sep Y -> Apr (Y+1) for a Fall session code' do
      c = make_course('CSC999H1Y-20259', 'CSC999H1Y 20259')
      task.invoke
      expect_dates(c, '2025-09-01', '2026-04-30')
    end
  end

  describe 'demo and sandbox exclusions' do
    it 'skips when name matches /sandbox/' do
      c = make_course('ds-sandbox', 'Data Science Sandbox')
      task.invoke
      c.reload
      expect(c.start_at).to be_nil
      expect(c.end_at).to be_nil
    end

    it 'skips when display_name matches /demo/ even though name has a parseable date' do
      c = make_course('fakedemo', 'Fake Demo Course 2024-09')
      task.invoke
      c.reload
      expect(c.start_at).to be_nil
      expect(c.end_at).to be_nil
    end

    it 'skips when only display_name matches /sandbox/' do
      c = make_course('GRE101H1-F-LEC0101', "GRE101:Ryan's fourth sandbox")
      task.invoke
      c.reload
      expect(c.start_at).to be_nil
      expect(c.end_at).to be_nil
    end
  end

  describe 'idempotency and partial population' do
    it 'leaves a fully-populated course untouched' do
      original_start = Time.zone.parse('2020-01-01')
      original_end = Time.zone.parse('2020-04-30')
      c = make_course('csc110-2024-09', start_at: original_start, end_at: original_end)
      task.invoke
      c.reload
      expect(c.start_at).to be_within(1.second).of(original_start)
      expect(c.end_at).to be_within(1.second).of(original_end)
    end

    it 'fills only the missing field when one is already set' do
      preset_start = Time.zone.parse('2024-08-15')
      c = make_course('csc110-2024-09', start_at: preset_start)
      task.invoke
      c.reload
      expect(c.start_at).to be_within(1.second).of(preset_start)
      expect(c.end_at.to_date.iso8601).to eq('2024-12-31')
    end

    it 'leaves dates unchanged on a second run' do
      c = make_course('csc110-2024-09')
      task.invoke
      c.reload
      original_start, original_end = c.start_at, c.end_at

      task.reenable
      task.invoke
      c.reload
      expect(c.start_at).to eq(original_start)
      expect(c.end_at).to eq(original_end)
    end
  end

  describe 'validation failures' do
    it 'skips and logs without raising when the existing date conflicts with the computed one' do
      preset_start = Time.zone.parse('2099-01-01')
      bad = make_course('csc110-2024-09', start_at: preset_start)
      good = make_course('csc111-2026-01', 'Foundations II')

      expect { task.invoke }.to output(/\[invalid\b/).to_stdout
      bad.reload
      expect(bad.start_at).to be_within(1.second).of(preset_start)
      expect(bad.end_at).to be_nil
      expect_dates(good, '2026-01-01', '2026-04-30')
    end
  end

  describe 'unparseable and dry-run' do
    it 'skips a course whose name and display_name lack any year/session match' do
      c = make_course('csc1500', 'Some title with no date')
      task.invoke
      c.reload
      expect(c.start_at).to be_nil
      expect(c.end_at).to be_nil
    end

    it 'does not write to the DB when DRY_RUN=1' do
      c = make_course('csc110-2024-09', 'Foundations')
      stub_const('ENV', ENV.to_h.merge('DRY_RUN' => '1'))
      task.invoke
      c.reload
      expect(c.start_at).to be_nil
      expect(c.end_at).to be_nil
    end
  end

  describe 'timezone' do
    it 'sets timestamps in Toronto local time' do
      c = make_course('csc110-2024-09')
      task.invoke
      c.reload
      expect(c.start_at.in_time_zone('America/Toronto').strftime('%Y-%m-%d %H:%M')).to eq('2024-09-01 00:00')
      expect(c.end_at.in_time_zone('America/Toronto').strftime('%Y-%m-%d %H:%M')).to eq('2024-12-31 23:59')
    end
  end
end
