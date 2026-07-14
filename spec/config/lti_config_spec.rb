describe LtiConfig do
  let(:deployment) do
    OpenStruct.new(
      lms_course_sourcedid: nil,
      lms_term_name: nil,
      lms_course_name: nil
    )
  end

  describe '.get_course_name' do
    context 'when SIS ID is valid' do
      it 'extracts the code, session, and term' do
        deployment.lms_course_sourcedid = 'LSM999Y1-Y-LEC0101-20259'
        result = LtiConfig.get_course_name(deployment, 'LSM999')
        expect(result).to eq('LSM999Y1Y-20259')
      end
    end

    context 'when SIS ID is the failed variable string' do
      it 'uses the fallback logic with course_code and term' do
        deployment.lms_course_sourcedid = '$CourseSection.sourcedId'
        deployment.lms_term_name = 'Fall 2025'
        result = LtiConfig.get_course_name(deployment, 'CSC108')
        expect(result).to eq('CSC108-20259')
      end
    end

    context 'when characters need cleaning' do
      it 'upcases and replaces invalid characters with hyphens' do
        deployment.lms_course_sourcedid = nil
        deployment.lms_term_name = 'Winter 2026'
        result = LtiConfig.get_course_name(deployment, 'csc 108!')
        expect(result).to eq('CSC-108-20261')
      end
    end
  end

  describe '.get_course_dates' do
    subject(:dates) { LtiConfig.get_course_dates(deployment) }

    context 'when parsing the term name' do
      it 'spans Fall from Sep 1 to Dec 31' do
        deployment.lms_term_name = 'Fall 2025'
        expect(dates).to eq([Time.zone.local(2025, 9, 1), Time.zone.local(2025, 12, 31).end_of_day])
      end

      it 'spans Winter from Jan 1 to Apr 30' do
        deployment.lms_term_name = 'Winter 2026'
        expect(dates).to eq([Time.zone.local(2026, 1, 1), Time.zone.local(2026, 4, 30).end_of_day])
      end

      it 'spans Summer from May 1 to Aug 31' do
        deployment.lms_term_name = 'Summer 2025'
        expect(dates).to eq([Time.zone.local(2025, 5, 1), Time.zone.local(2025, 8, 31).end_of_day])
      end

      it 'parses SCS-prefixed terms like the plain term' do
        deployment.lms_term_name = 'SCS Fall 2025'
        expect(dates).to eq([Time.zone.local(2025, 9, 1), Time.zone.local(2025, 12, 31).end_of_day])
      end

      it 'expands a 2-digit Fall year' do
        deployment.lms_term_name = 'Fall 25'
        expect(dates).to eq([Time.zone.local(2025, 9, 1), Time.zone.local(2025, 12, 31).end_of_day])
      end

      it 'expands a 2-digit Winter year' do
        deployment.lms_term_name = 'Winter 26'
        expect(dates).to eq([Time.zone.local(2026, 1, 1), Time.zone.local(2026, 4, 30).end_of_day])
      end

      it 'returns times in the application time zone' do
        deployment.lms_term_name = 'Fall 2025'
        expect(dates.first.utc_offset).to eq(Time.zone.local(2025, 9, 1).utc_offset)
      end
    end

    context 'when the term name is unparseable' do
      it 'returns nil for a season-less term name' do
        deployment.lms_term_name = 'Default Term'
        expect(dates).to be_nil
      end

      it 'returns nil for a blank term name' do
        deployment.lms_term_name = ''
        expect(dates).to be_nil
      end

      it 'returns nil for a whitespace-only term name' do
        deployment.lms_term_name = '   '
        expect(dates).to be_nil
      end

      it 'returns nil for an unexpanded Canvas variable' do
        deployment.lms_term_name = '$Canvas.term.name'
        expect(dates).to be_nil
      end

      it 'returns nil for a year without a season' do
        deployment.lms_term_name = '2025'
        expect(dates).to be_nil
      end
    end

    context 'when parsing the SIS ID term code' do
      it 'decodes a Fall term code' do
        deployment.lms_course_sourcedid = 'LSM999Y1-Y-LEC0101-20259'
        expect(dates).to eq([Time.zone.local(2025, 9, 1), Time.zone.local(2025, 12, 31).end_of_day])
      end

      it 'decodes a Winter term code' do
        deployment.lms_course_sourcedid = 'LSM999Y1-Y-LEC0101-20261'
        expect(dates).to eq([Time.zone.local(2026, 1, 1), Time.zone.local(2026, 4, 30).end_of_day])
      end

      it 'decodes a 2-digit month and crosses the year boundary' do
        deployment.lms_course_sourcedid = 'LSM999Y1-Y-LEC0101-202511'
        expect(dates).to eq([Time.zone.local(2025, 11, 1), Time.zone.local(2026, 2, 28).end_of_day])
      end

      it 'wins over a disagreeing term name' do
        deployment.lms_course_sourcedid = 'LSM999Y1-Y-LEC0101-20259'
        deployment.lms_term_name = 'Winter 2030'
        expect(dates.first).to eq(Time.zone.local(2025, 9, 1))
      end
    end

    context 'when the SIS ID term code is malformed' do
      before { deployment.lms_term_name = 'Winter 2026' }

      it 'falls through to the term name for a month of zero' do
        deployment.lms_course_sourcedid = 'ABC123H1-F-LEC0101-20250'
        expect(dates.first).to eq(Time.zone.local(2026, 1, 1))
      end

      it 'falls through to the term name for a month over twelve' do
        deployment.lms_course_sourcedid = 'ABC123H1-F-LEC0101-202590'
        expect(dates.first).to eq(Time.zone.local(2026, 1, 1))
      end

      it 'falls through to the term name for a year-only code' do
        deployment.lms_course_sourcedid = 'ABC123H1-F-LEC0101-2025'
        expect(dates.first).to eq(Time.zone.local(2026, 1, 1))
      end

      it 'falls through to the term name for a 2-digit code' do
        deployment.lms_course_sourcedid = 'ABC123H1-F-LEC0101-99'
        expect(dates.first).to eq(Time.zone.local(2026, 1, 1))
      end

      it 'falls through to the term name for an unexpanded variable' do
        deployment.lms_course_sourcedid = '$CourseSection.sourcedId'
        expect(dates.first).to eq(Time.zone.local(2026, 1, 1))
      end

      it 'returns nil when the term name is also unparseable' do
        deployment.lms_term_name = nil
        deployment.lms_course_sourcedid = 'ABC123H1-F-LEC0101-20250'
        expect(dates).to be_nil
      end
    end
  end

  describe '.get_course_suffix' do
    it 'handles standard Fall term' do
      expect(LtiConfig.get_course_suffix('Fall 2025')).to eq('20259')
    end

    it 'handles standard Winter term' do
      expect(LtiConfig.get_course_suffix('Winter 2026')).to eq('20261')
    end

    it 'handles standard Summer term' do
      expect(LtiConfig.get_course_suffix('Summer 2025')).to eq('20255')
    end

    it 'handles SCS prefix' do
      expect(LtiConfig.get_course_suffix('SCS Fall 2025')).to eq('SCS-20259')
    end

    it 'falls back to a cleaned string if no month/year found' do
      expect(LtiConfig.get_course_suffix('Default Term')).to eq('DEFAULT-TERM')
    end
  end
end
