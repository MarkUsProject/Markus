describe DownloadSubmissionsJob do
  let(:assignment) { create(:assignment) }
  let(:groupings) do
    create_list(:grouping_with_inviter, 3, assignment: assignment).map do |grouping|
      gid = grouping.id
      submit_file(assignment, grouping, "file#{gid}", "file#{gid}'s content\n")
      grouping
    end
  end

  let(:groupings_without_files) { create_list(:grouping, 3) }

  context 'when running as a background job' do
    let(:job_args) { [groupings.map(&:id), 'zip_path.zip', assignment.id, assignment.course_id] }

    it_behaves_like 'background job'
  end

  context 'when print is false' do
    it 'should create a zip file containing all submission files for the given groupings' do
      zip_path = 'tmp/test_file.zip'
      DownloadSubmissionsJob.perform_now(groupings.map(&:id), zip_path, assignment.id, assignment.course.id,
                                         print: false)
      Zip::File.open(zip_path) do |zip_file|
        groupings.each do |grouping|
          gid = grouping.id
          zip_entry = Pathname.new(grouping.group.group_name) + "file#{gid}"
          expect(zip_file.find_entry(zip_entry)).not_to be_nil
          expect("file#{gid}'s content\n").to eq(zip_file.read(zip_entry))
        end
      end
    end

    it 'should skip files for groupings that do not have a submission for that assignment' do
      zip_path = 'tmp/test_file.zip'
      DownloadSubmissionsJob.perform_now(groupings_without_files.map(&:id), zip_path, assignment.id,
                                         assignment.course.id, print: false)
      Zip::File.open(zip_path) do |zip_file|
        groupings_without_files.each do |grouping|
          gid = grouping.id
          zip_entry = Pathname.new(grouping.group.group_name) + "file#{gid}"
          expect(zip_file.find_entry(zip_entry)).to be_nil
        end
      end
    end
  end

  context 'when print is true' do
    it 'should create a zip file containing a PDF for each given grouping' do
      zip_path = 'tmp/test_file.zip'
      DownloadSubmissionsJob.perform_now(groupings.map(&:id), zip_path, assignment.id, assignment.course.id,
                                         print: true)
      Zip::File.open(zip_path) do |zip_file|
        groupings.each do |grouping|
          student = grouping.accepted_students.first.user
          zip_entry =
            "#{student.id_number} - #{student.last_name.upcase}, #{student.first_name} (#{student.user_name}).pdf"
          expect(zip_file.find_entry(zip_entry)).not_to be_nil
        end
      end
    end
  end

  it 'should remove the previous zip file if it exists' do
    zip_path = 'tmp/test_file.zip'
    before_text = 'the before text'
    File.write(zip_path, before_text)
    DownloadSubmissionsJob.perform_now(groupings.map(&:id), zip_path, assignment.id, assignment.course.id, print: false)
    expect(File.read(zip_path)).not_to eq before_text
  end
end
