namespace :db do
  desc 'Update fake marks for assignments'
  task marks: :environment do
    puts 'Assign Marks for Assignments 0-2'

    Assignment.find_by(short_identifier: 'A0').update(due_date: 24.hours.ago)
    Assignment.where(short_identifier: %w[A1 A2]).update_all(due_date: Time.current)

    # Create collected submissions for all groupings
    submission_ids = []
    groupings = Grouping.joins(:assignment).where(assessments: { short_identifier: %w[A0 A1 A2] })
    groupings.each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      submission_ids << new_submission.id

      if grouping.assignment.short_identifier == 'A0'
        grouping.assignment.submission_rule.apply_submission_rule(new_submission)
      end
    end
    groupings.update_all(is_collected: true)

    # Add feedback files to submissions
    text1 = File.read('db/data/feedback_files/humanfb.txt', mode: 'rb')
    text2 = File.read('db/data/feedback_files/machinefb.txt', mode: 'rb')
    image = File.read('db/data/feedback_files/imagefb.png', mode: 'rb')

    feedback_files = submission_ids.flat_map do |sid|
      attrs = { submission_id: sid, created_at: Time.current, updated_at: Time.current }
      [attrs.merge(filename: 'humanfb.txt', mime_type: 'text', file_content: "#{sid}\n#{text1}"),
       attrs.merge(filename: 'machinefb.txt', mime_type: 'text', file_content: "#{sid}\n#{text2}"),
       attrs.merge(filename: 'imagefb.png', mime_type: 'image/png', file_content: image)]
    end
    FeedbackFile.insert_all feedback_files

    # Add annotations to submissions
    instructor = Instructor.first
    now = Time.current
    annotation_attributes = {
      is_remark: false, creator_id: instructor.id, creator_type: 'Instructor',
      x1: nil, y1: nil, x2: nil, y2: nil, page: nil,
      line_start: nil, line_end: nil, column_start: nil, column_end: nil
    }
    image_annotation_attributes = annotation_attributes.merge(
      type: 'ImageAnnotation', x1: 132, y1: 199, x2: 346, y2: 370
    )
    pdf_annotation_attributes = annotation_attributes.merge(
      type: 'PdfAnnotation', x1: 27_740, y1: 58_244, x2: 4977, y2: 29_748, page: 1
    )
    text_annotation_attributes = annotation_attributes.merge(
      type: 'TextAnnotation', line_start: 7, line_end: 9, column_start: 6, column_end: 15
    )
    text_annotation_attributes2 = annotation_attributes.merge(
      type: 'TextAnnotation', line_start: 4, line_end: 5, column_start: 6, column_end: 15
    )
    text_annotation_attributes3 = annotation_attributes.merge(
      type: 'TextAnnotation', line_start: 12, line_end: 12, column_start: 1, column_end: 26
    )

    submission_file_ids = Submission.where('submissions.id': submission_ids,
                                           'submission_files.filename': %w[deferred-process.jpg pdf.pdf hello.py])
                                    .includes(:submission_files)
                                    .pluck('submissions.id', 'submission_files.filename', 'submission_files.id')
                                    .group_by { |x| [x[0], x[1]] }
                                    .transform_values! { |x| x[0][2] }

    annotation_text_ids = {}
    Assignment.where('assessments.short_identifier': %w[A0 A1 A2]).find_each do |a|
      annotation_text_ids[a.id] = a.annotation_categories.joins(:annotation_texts)
                                   .where('annotation_categories.flexible_criterion_id': nil)
                                   .pluck('annotation_texts.id')
    end

    # The deductive annotation categories for each assignment.
    # There should be two per assignment.
    deductive_categories = {}
    Assignment.where('assessments.short_identifier': %w[A0 A1 A2]).find_each do |a|
      deductive_categories[a.id] = a.annotation_categories.where.not(flexible_criterion_id: nil).map do |cat|
        { criterion_id: cat.flexible_criterion_id, text_ids: cat.annotation_texts.ids }
      end
    end

    criteria = Assignment.includes(:criteria).where('assessments.short_identifier': %w[A0 A1 A2]).map do |a|
      [a.id, a.criteria.pluck_to_hash(:id, :type, :max_mark)]
    end.to_h

    one_time_ids = AnnotationText.insert_all(groupings.map do |_|
      {
        content: random_sentences(3),
        creator_id: instructor.id,
        last_editor_id: instructor.id,
        created_at: now,
        updated_at: now
      }
    end)
    one_time_ids = one_time_ids.pluck('id')

    annotations = []
    marks = []
    results = []

    groupings.joins(:current_result).pluck('groupings.assessment_id', 'results.id', 'results.submission_id')
             .each_with_index do |data, i|
      assignment_id, result_id, submission_id = data

      texts = annotation_text_ids[assignment_id]
      cat1, cat2 = deductive_categories[assignment_id]

      # Image annotation (from category)
      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'deferred-process.jpg']],
        annotation_text_id: texts.sample,
        annotation_number: 1,
        **image_annotation_attributes
      }

      # PDF annotation (from category)
      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'pdf.pdf']],
        annotation_text_id: texts.sample,
        annotation_number: 2,
        **pdf_annotation_attributes
      }

      # PDF annotation (one-time-only)
      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'pdf.pdf']],
        annotation_text_id: one_time_ids[i],
        annotation_number: 3,
        type: 'PdfAnnotation', x1: 52_444, y1: 20_703, x2: 88_008, y2: 35_185, page: 2, **annotation_attributes
      }

      # Text file annotation (from category)
      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'hello.py']],
        annotation_text_id: texts.sample,
        annotation_number: 4,
        **text_annotation_attributes
      }

      # Deductive annotations (two per submission)
      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'hello.py']],
        annotation_text_id: cat1[:text_ids].sample,
        annotation_number: 5,
        **text_annotation_attributes2
      }

      annotations << {
        result_id: result_id,
        submission_file_id: submission_file_ids[[submission_id, 'hello.py']],
        annotation_text_id: cat2[:text_ids].sample,
        annotation_number: 6,
        **text_annotation_attributes3
      }

      # Generate grades for the submission
      criteria[assignment_id].each do |criterion|
        override = false
        if criterion[:type] == 'RubricCriterion'
          random_mark = criterion[:max_mark] / 4 * rand(0..4)
        elsif criterion[:type] == 'CheckboxCriterion'
          random_mark = rand(0..1)
        elsif criterion[:id] == cat1[:criterion_id] # FlexibleCriterion, which may involve a deductive annotation
          random_mark = 0 # Deductive annotation causes mark of 0
        elsif criterion[:id] == cat2[:criterion_id] # Deductive annotation is overridden
          override = true
          random_mark = criterion[:max_mark]
        else
          random_mark = rand(0..criterion[:max_mark])
        end
        marks << {
          result_id: result_id,
          criterion_id: criterion[:id],
          mark: random_mark,
          override: override,
          created_at: now,
          updated_at: now
        }
      end
      results << {
        id: result_id,
        marking_state: Result::MARKING_STATES[:complete],
        released_to_students: true,
        view_token: Result.generate_unique_secure_token
      }
    end
    Annotation.insert_all annotations

    Mark.joins(criterion: :assignment)
        .where(assessments: { short_identifier: %w[A0 A1 A2] }).destroy_all
    Mark.insert_all marks

    Result.upsert_all results

    puts 'Assign Marks for Spreadsheets'
    grades = []
    students = []
    # Quiz1
    grade_entry_form = GradeEntryForm.first
    # Add marks to every student
    grade_entry_form.grade_entry_students.find_each do |student|
      # For each question, assign a random mark based on its out_of value
      grade_entry_form.grade_entry_items.each do |grade_entry_item|
        random_grade = 1 + rand(0...Integer(grade_entry_item.out_of))
        grades << {
          grade_entry_student_id: student.id,
          grade_entry_item_id: grade_entry_item.id,
          grade: random_grade
        }
      end
      students << { id: student.id, role_id: student.role.id, released_to_student: true }
    end

    Grade.insert_all grades
    GradeEntryStudent.upsert_all students
  end
end
