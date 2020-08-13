namespace :db do

  desc 'Update fake marks for assignments'
  task :marks => :environment do
    puts 'Assign Marks for Assignments (This may take a while)'

    Assignment.find_by(short_identifier: 'A0').update(due_date: 24.hours.ago)
    Assignment.where(short_identifier: %w[A1 A2]).update_all(due_date: Time.current)

    # Open the text for the feedback files to reference
    mfile = File.open("db/data/feedback_files/machinefb.txt", "rb")
    hfile = File.open("db/data/feedback_files/humanfb.txt", "rb")
    mcont = mfile.read
    hcont = hfile.read
    mfile.close
    hfile.close
    feedbackfiles = []
    annotation_texts = []
    marks = []
    #Right now, only generate marks for three assignments
    annotations = []
    results = []
    one_time_num = AnnotationText.all.pluck(:id).max + 1
    criteria = Hash[Assignment.includes(:criteria).where('assessments.short_identifier': %w[A0 A1 A2]).map do |a|
      [a.id, a.criteria.pluck(:id, :type, :max_mark)]
    end
    ]
    categories_with_criteria = Hash[Assignment.includes(:annotation_categories)
                                              .where('assessments.short_identifier': %w[A0 A1 A2]).map do |a|
      [a.id, a.annotation_categories.joins(:annotation_texts)
                                    .where.not(flexible_criterion_id: nil)
                                    .group('annotation_categories.id',
                                           'annotation_categories.flexible_criterion_id')
                                    .pluck('annotation_categories.id',
                                           'annotation_categories.flexible_criterion_id',
                                           'MAX(annotation_texts.id)')]
    end
    ]
    Grouping.joins(:assignment).where(assessments: { short_identifier: %w[A0 A1 A2] }).each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      result = new_submission.results.first
      grouping.is_collected = true
      grouping.save

      if grouping.assignment.short_identifier == 'A0'
        grouping.assignment.submission_rule.apply_submission_rule(new_submission)
      end

      # add a human written feedback file
      feedbackfiles << {
        submission_id: new_submission.id,
        filename: 'humanfb',
        mime_type: 'text',
        file_content: hcont,
        created_at: Time.now,
        updated_at: Time.now
      }

      # add an machine-generated feedback file
      feedbackfiles << {
        submission_id: new_submission.id,
        filename: 'machinefb',
        mime_type: 'text',
        file_content: mcont,
        created_at: Time.now,
        updated_at: Time.now
      }

      submission_file = new_submission.submission_files.find_by(filename: 'deferred-process.jpg')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all
                                          .joins(:annotation_category)
                                          .where('annotation_categories.assignment': grouping.assignment,
                                                 'annotation_texts.deduction': nil)
                                          .where.not('annotation_texts.annotation_category_id': nil)
                                          .pluck(:id).sample,
        annotation_number: 1,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      annotations << {
        line_start: nil,
        line_end: nil,
        column_end: nil,
        column_start: nil,
        type: 'ImageAnnotation',
        page: nil,
        x1: 132,
        y1: 199,
        x2: 346,
        y2: 370,
        **base_attributes
      }


      submission_file = new_submission.submission_files.find_by(filename: 'pdf.pdf')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all
                                          .joins(:annotation_category)
                                          .where('annotation_categories.assignment': grouping.assignment,
                                                 'annotation_texts.deduction': nil)
                                          .where.not('annotation_texts.annotation_category_id': nil)
                                          .pluck(:id).sample,
        annotation_number: 2,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      annotations << {
        line_start: nil,
        line_end: nil,
        column_end: nil,
        column_start: nil,
        type: 'PdfAnnotation',
        x1: 27_740,
        y1: 58_244,
        x2: 4977,
        y2: 29_748,
        page: 1,
        **base_attributes
      }

      one_time_only = {
        id: one_time_num,
        annotation_category_id: nil,
        content: random_sentences(3),
        creator_id: Admin.first,
        last_editor_id: Admin.first,
        updated_at: Time.now,
        created_at: Time.now,
        deduction: nil
      }
      one_time_num += 1
      annotation_texts << one_time_only

      base_attributes[:annotation_text_id] = one_time_only[:id]
      base_attributes[:annotation_number] = 3
      annotations << {
        line_start: nil,
        line_end: nil,
        column_end: nil,
        column_start: nil,
        type: 'PdfAnnotation',
        x1: 52_444,
        y1: 20_703,
        x2: 88_008,
        y2: 35_185,
        page: 2,
        **base_attributes
      }

      submission_file = new_submission.submission_files.find_by(filename: 'hello.py')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all
                                          .joins(:annotation_category)
                                          .where('annotation_categories.assignment': grouping.assignment,
                                                 'annotation_texts.deduction': nil)
                                          .where.not('annotation_texts.annotation_category_id': nil)
                                          .pluck(:id).sample,
        annotation_number: 4,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      annotations << {
        type: 'TextAnnotation',
        line_start: 7,
        line_end: 9,
        column_start: 6,
        column_end: 15,
        x1: nil,
        y1: nil,
        x2: nil,
        y2: nil,
        page: nil,
        **base_attributes
      }

      total_mark = 0
      #Automate marks for assignment using appropriate criteria
      criteria[grouping.assignment.id].each do |criterion|
        override = false
        if criterion[1] == 'RubricCriterion'
          random_mark = criterion[2] / 4 * rand(0..4)
        elsif criterion[1] == 'FlexibleCriterion'
          if categories_with_criteria[grouping.assignment.id][0][1] == criterion[0]
            base_attributes[:annotation_text_id] = categories_with_criteria[grouping.assignment.id][0][2]
            base_attributes[:annotation_number] = 5
            annotations << {
              type: 'TextAnnotation',
              line_start: 4,
              line_end: 5,
              column_start: 6,
              column_end: 15,
              x1: nil,
              y1: nil,
              x2: nil,
              y2: nil,
              page: nil,
              **base_attributes
            }
            random_mark = 0
          elsif categories_with_criteria[grouping.assignment.id][1][1] == criterion[0]
            base_attributes[:annotation_text_id] = categories_with_criteria[grouping.assignment.id][1][2]
            base_attributes[:annotation_number] = 6
            annotations << {
              type: 'TextAnnotation',
              line_start: 12,
              line_end: 12,
              column_start: 1,
              column_end: 26,
              x1: nil,
              y1: nil,
              x2: nil,
              y2: nil,
              page: nil,
              **base_attributes
            }
            override = true
            random_mark = criterion[2]
          else
            random_mark = rand(0..criterion[2])
          end
        else
          random_mark = rand(0..1)
        end
        total_mark += random_mark
        marks << {
          result_id: result.id,
          criterion_id: criterion[0],
          mark: random_mark,
          created_at: Time.now,
          updated_at: Time.now,
          override: override
        }
      end
      results << { id: result.id, total_mark: total_mark, marking_state: 'complete', released_to_students: true }
    end
    FeedbackFile.insert_all feedbackfiles
    AnnotationText.upsert_all annotation_texts

    Mark
      .joins(result: [submission: [grouping: :assignment]])
      .where(assessments: { short_identifier: %w[A0 A1 A2] }).destroy_all
    Mark.insert_all marks

    puts 'Release Results for Assignments'
    Result.upsert_all results

    Assignment.where(short_identifier: %w(A0 A1 A2)).each do |a|
      a.update_results_stats
      a.assignment_stat.refresh_grade_distribution
    end

    puts 'Assign Marks for Spreadsheets'
    grades = []
    students = []
    # Quiz1
    grade_entry_form = GradeEntryForm.first
    # Add marks to every student
    grade_entry_form.grade_entry_students.find_each do |student|
      # For each question, assign a random mark based on its out_of value
      total_grade = 0
      grade_entry_form.grade_entry_items.each do |grade_entry_item|
        random_grade = 1 + rand(0...Integer(grade_entry_item.out_of))
        total_grade += random_grade
        grades << {
          grade_entry_student_id: student.id,
          grade_entry_item_id: grade_entry_item.id,
          grade: random_grade,
          created_at: Time.now,
          updated_at: Time.now
        }
      end
      students << { id: student.id, total_grade: total_grade}
    end

    Grade.insert_all grades
    GradeEntryStudent.upsert_all students

    # Release spreadsheet grades
    grade_entry_form.grade_entry_students.update_all(released_to_student: true)
  end
end
