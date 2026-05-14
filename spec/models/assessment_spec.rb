describe Assessment do
  it { is_expected.not_to allow_value('Mike Ooh').for(:short_identifier) }
  it { is_expected.not_to allow_value('A!a.sa').for(:short_identifier) }

  it { is_expected.to allow_value('Ads_-hb').for(:short_identifier) }
  it { is_expected.to allow_value('-22125-k1lj42_').for(:short_identifier) }
  it { is_expected.to belong_to(:course) }

  it 'throws error when short_identifier fails format validation' do
    assessment = Assessment.new(
      course: create(:course),
      description: 'mock description',
      is_hidden: false,
      short_identifier: 'Invalid@!'
    )

    expect(assessment).not_to be_valid
    error_key = 'activerecord.errors.models.assessment.attributes.short_identifier.invalid'
    expected_error = I18n.t(error_key, attribute: 'Short identifier')
    expect(assessment.errors[:short_identifier]).to include(expected_error)
  end

  describe 'datetime visibility validation' do
    let(:course) { create(:course) }

    it 'allows nil visible_on and visible_until' do
      assessment = create(:assignment, course: course, visible_on: nil, visible_until: nil)
      expect(assessment).to be_valid
    end

    it 'allows only visible_on to be set' do
      assessment = create(:assignment, course: course, visible_on: 1.day.ago, visible_until: nil)
      expect(assessment).to be_valid
    end

    it 'allows only visible_until to be set' do
      assessment = create(:assignment, course: course, visible_on: nil, visible_until: 1.day.from_now)
      expect(assessment).to be_valid
    end

    it 'allows visible_on before visible_until' do
      assessment = create(:assignment, course: course, visible_on: 1.day.ago, visible_until: 1.day.from_now)
      expect(assessment).to be_valid
    end

    it 'rejects visible_on equal to visible_until' do
      time = Time.current
      assessment = build(:assignment, course: course, visible_on: time, visible_until: time)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:visible_until]).to include('must be after visible_on')
    end

    it 'rejects visible_on after visible_until' do
      assessment = build(:assignment, course: course, visible_on: 1.day.from_now, visible_until: 1.day.ago)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:visible_until]).to include('must be after visible_on')
    end
  end

  describe 'LTI line item resync on update' do
    let(:assignment) { create(:assignment) }
    let(:lti_deployment) { create(:lti_deployment, course: assignment.course) }

    context 'when no LTI line item exists for the assessment' do
      it 'does not enqueue a sync job on due_date change' do
        expect(LtiLineItemJob).not_to receive(:perform_later)
        assignment.update!(due_date: 2.days.from_now)
      end
    end

    context 'when an LTI line item exists for the assessment' do
      before { create(:lti_line_item, lti_deployment: lti_deployment, assessment: assignment) }

      it 'enqueues a sync job when due_date changes' do
        expect(LtiLineItemJob).to receive(:perform_later).with([lti_deployment.id], assignment)
        assignment.update!(due_date: 3.days.from_now)
      end

      it 'enqueues a sync job when description changes' do
        expect(LtiLineItemJob).to receive(:perform_later).with([lti_deployment.id], assignment)
        assignment.update!(description: 'updated description')
      end

      it 'does not enqueue when only an unrelated attribute changes' do
        expect(LtiLineItemJob).not_to receive(:perform_later)
        assignment.update!(message: 'unrelated change')
      end
    end
  end
end
