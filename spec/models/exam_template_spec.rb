describe ExamTemplate do
  let(:exam_template) { create(:exam_template_midterm) }
  let(:group) { create(:group, course: exam_template.course) }
  let(:grouping) { create(:grouping, group: group, assignment: exam_template.assignment) }

  describe '#missing_pages' do
    it 'returns all page numbers when no pages have been scanned' do
      expect(exam_template.missing_pages(group)).to eq (1..6).to_a
    end

    it 'returns only the unscanned page numbers when some pages exist' do
      create(:split_page, group: group, exam_page_number: 2)
      create(:split_page, group: group, exam_page_number: 4)
      expect(exam_template.missing_pages(group)).to eq [1, 3, 5, 6]
    end

    it 'returns an empty array when all pages have been scanned' do
      (1..6).each { |n| create(:split_page, group: group, exam_page_number: n) }
      expect(exam_template.missing_pages(group)).to eq []
    end
  end

  describe '#paper_complete?' do
    it 'is false when pages are missing' do
      expect(exam_template.paper_complete?(group)).to be false
    end

    it 'is true when every page has been scanned' do
      (1..6).each { |n| create(:split_page, group: group, exam_page_number: n) }
      expect(exam_template.paper_complete?(group)).to be true
    end
  end

  describe '#collect_if_complete' do
    context 'when the paper is complete and not yet collected' do
      before { (1..6).each { |n| create(:split_page, group: group, exam_page_number: n) } }

      it 'collects the submission' do
        exam_template.collect_if_complete(grouping)
        expect(grouping.reload.is_collected?).to be true
      end
    end

    context 'when the paper is incomplete' do
      before { create(:split_page, group: group, exam_page_number: 1) }

      it 'does not collect the submission' do
        exam_template.collect_if_complete(grouping)
        expect(grouping.reload.is_collected?).to be false
      end
    end

    context 'when the paper is complete but already collected' do
      before do
        (1..6).each { |n| create(:split_page, group: group, exam_page_number: n) }
        grouping.update!(is_collected: true)
      end

      it 'does not attempt to recollect' do
        expect(SubmissionsJob).not_to receive(:perform_now)
        exam_template.collect_if_complete(grouping)
      end
    end
  end
end
