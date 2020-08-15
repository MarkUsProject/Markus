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
      [a.id, a.criteria.pluck_to_hash(:id, :type, :max_mark)]
    end
    ]
    categories_with_criteria = Hash[Assignment.includes(:annotation_categories)
                                              .where('assessments.short_identifier': %w[A0 A1 A2]).map do |a|
          [a.id, a.annotation_categories.joins(:annotation_texts)
                  .where.not(flexible_criterion_id: nil)
                  .group('annotation_categories.id',
                         'annotation_categories.flexible_criterion_id')
                  .pluck_to_hash('annotation_categories.id AS category_id',
                                 'annotation_categories.flexible_criterion_id AS category_crit_id',
                                 'MAX(annotation_texts.id) AS deductive_text')]
        end
      ]

    base_attributes = {
      submission_file_id: 1,
      is_remark: false,
      annotation_text_id: 1,
      annotation_number: 1,
      creator_id: Admin.first.id,
      creator_type: 'Admin',
      result_id: 1
    }
    annotation_text_ids = {}
    Assignment.all.where('assessments.short_identifier': %w[A0 A1 A2]).each do |a|
      annotation_text_ids[a.id] = a.annotation_categories.joins(:annotation_texts)
                                   .where('annotation_categories.flexible_criterion_id': nil)
                                   .pluck('annotation_texts.id')
    end

    submission_ids = []

    Grouping.joins(:assignment).where(assessments: { short_identifier: %w[A0 A1 A2] }).each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      submission_ids << new_submission.id
      grouping.is_collected = true
      grouping.save

      if grouping.assignment.short_identifier == 'A0'
        grouping.assignment.submission_rule.apply_submission_rule(new_submission)
      end
    end

    submission_file_data = Submission.all.includes(:submission_files)
                                     .where('submissions.id': submission_ids,
                                            'submission_files.filename': %w[deferred-process.jpg pdf.pdf hello.py])
                                     .pluck('submissions.id', 'submission_files.filename', 'submission_files.id')

    submission_file_ids = submission_file_data.inject({}) { |data, item| data.merge(item[0].to_s + item[1] => item[2])}

    Grouping.joins(:assignment).where(assessments: { short_identifier: %w[A0 A1 A2] }).each do |grouping|
      submission = grouping.current_submission_used
      result = submission.results.first
      base_attributes[:result_id] = result.id

      # add a human written feedback file
      feedbackfiles << {
        submission_id: submission.id,
        filename: 'humanfb',
        mime_type: 'text',
        file_content: hcont,
        created_at: Time.now,
        updated_at: Time.now
      }

      # add an machine-generated feedback file
      feedbackfiles << {
        submission_id: submission.id,
        filename: 'machinefb',
        mime_type: 'text',
        file_content: mcont,
        created_at: Time.now,
        updated_at: Time.now
      }

      base_attributes[:submission_file_id] = submission_file_ids[submission.id.to_s + 'deferred-process.jpg']
      base_attributes[:annotation_text_id] = annotation_text_ids[grouping.assignment.id].sample
      base_attributes[:annotation_number] = 1
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


      base_attributes[:submission_file_id] = submission_file_ids[submission.id.to_s + 'pdf.pdf']
      base_attributes[:annotation_text_id] = annotation_text_ids[grouping.assignment.id].sample
      base_attributes[:annotation_number] = 2
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
        deduction: nil,
        created_at: Time.now,
        updated_at: Time.now
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

      base_attributes[:submission_file_id] = submission_file_ids[submission.id.to_s + 'hello.py']
      base_attributes[:annotation_text_id] = annotation_text_ids[grouping.assignment.id].sample
      base_attributes[:annotation_number] = 4
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
      categories_for_assignment = categories_with_criteria[grouping.assignment.id]
      deductive_category = categories_for_assignment[0]
      overridden_category = categories_for_assignment[1]
      #Automate marks for assignment using appropriate criteria
      criteria[grouping.assignment.id].each do |criterion|
        override = false
        if criterion[:type] == 'RubricCriterion'
          random_mark = criterion[:max_mark] / 4 * rand(0..4)
        elsif criterion[:type] == 'FlexibleCriterion'
          if deductive_category[:category_crit_id] == criterion[:id]
            base_attributes[:annotation_text_id] = deductive_category[:deductive_text]
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
          elsif overridden_category[:category_crit_id] == criterion[:id]
            base_attributes[:annotation_text_id] = overridden_category[:deductive_text]
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
            random_mark = criterion[:max_mark]
          else
            random_mark = rand(0..criterion[:max_mark])
          end
        else
          random_mark = rand(0..1)
        end
        total_mark += random_mark
        marks << {
          result_id: result.id,
          criterion_id: criterion[:id],
          mark: random_mark,
          override: override,
          created_at: Time.now,
          updated_at: Time.now
        }
      end
      results << { id: result.id, total_mark: total_mark, marking_state: 'complete', released_to_students: true }
    end
    FeedbackFile.insert_all feedbackfiles
    AnnotationText.upsert_all annotation_texts
    Annotation.insert_all annotations

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
          grade: random_grade
        }
      end
      students << { id: student.id, total_grade: total_grade }
    end

    Grade.insert_all grades
    GradeEntryStudent.upsert_all students

    # Release spreadsheet grades
    grade_entry_form.grade_entry_students.update_all(released_to_student: true)
  end
end
