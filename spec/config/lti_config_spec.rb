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
