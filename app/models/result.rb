class Result < ApplicationRecord
  MARKING_STATES = {
    complete: 'complete',
    incomplete: 'incomplete'
  }.freeze

  belongs_to :submission
  has_one :grouping, through: :submission
  has_many :marks, dependent: :destroy
  has_many :extra_marks, dependent: :destroy
  has_many :annotations, dependent: :destroy
  has_many :peer_reviews, dependent: :destroy

  has_one :course, through: :submission

  has_secure_token :view_token

  before_save :check_for_nil_marks
  after_create :create_marks
  validates :marking_state, presence: true
  validates :marking_state, inclusion: { in: MARKING_STATES.values }

  validates :released_to_students, inclusion: { in: [true, false] }

  before_update :check_for_released

  # Release or unrelease the results of a set of groupings.
  def self.set_release_on_results(grouping_ids, release)
    groupings = Grouping.where(id: grouping_ids)
    without_submissions = groupings.where.not(id: groupings.joins(:current_submission_used))

    if without_submissions.present?
      group_names = without_submissions.joins(:group).pluck(:group_name).join(', ')
      raise StandardError, I18n.t('submissions.errors.no_submission', group_name: group_names)
    end

    assignment = groupings.first.assignment
    results = assignment.current_results.where('groupings.id': grouping_ids)
    incomplete_results = results.where('results.marking_state': Result::MARKING_STATES[:incomplete])

    without_complete_result = groupings.joins(:current_submission_used)
                                       .where('submissions.id': incomplete_results.pluck(:submission_id))

    if without_complete_result.present?
      group_names = without_complete_result.joins(:group).pluck(:group_name).join(', ')
      if release
        raise StandardError, I18n.t('submissions.errors.not_complete', group_name: group_names)
      else
        raise StandardError, I18n.t('submissions.errors.not_complete_unrelease', group_name: group_names)
      end
    end

    result = results.update_all(released_to_students: release)

    if release
      groupings.includes(:accepted_students).find_each do |grouping|
        next if grouping.assignment.release_with_urls  # don't email if release_with_urls is true
        grouping.accepted_students.each do |student|
          if student.receives_results_emails?
            NotificationMailer.with(user: student, grouping: grouping).release_email.deliver_later
          end
        end
      end
    end

    result
  end

  # Calculate the total mark for this submission
  def get_total_mark
    user_visibility = is_a_review? ? :peer_visible : :ta_visible
    Result.get_total_marks([self.id], user_visibility: user_visibility)[self.id]
  end

  # Return a hash mapping each id in +result_ids+ to the total mark for the result with that id.
  def self.get_total_marks(result_ids, user_visibility: :ta_visible, subtotals: nil, extra_marks: nil)
    subtotals ||= Result.get_subtotals(result_ids, user_visibility: user_visibility)
    extra_marks ||= Result.get_total_extra_marks(result_ids, user_visibility: user_visibility, subtotals: subtotals)
    subtotals.map { |r_id, subtotal| [r_id, [0, (subtotal || 0) + (extra_marks[r_id] || 0)].max] }.to_h
  end

  # The sum of the marks not including bonuses/deductions
  def get_subtotal
    if is_a_review?
      user_visibility = :peer_visible
    else
      user_visibility = :ta_visible
    end
    Result.get_subtotals([self.id], user_visibility: user_visibility)[self.id]
  end

  def self.get_subtotals(result_ids, user_visibility: :ta_visible, criterion_ids: nil)
    all_marks = Mark.joins(:criterion)
                    .where(result_id: result_ids, "criteria.#{user_visibility}": true)
    all_marks = all_marks.where('criteria.id': criterion_ids) if criterion_ids.present?

    marks = all_marks.group(:result_id).sum(:mark)
    result_ids.index_with { |r_id| marks[r_id] || 0 }
  end

  # The sum of the bonuses deductions and late penalties for multiple results.
  # This returns a hash mapping the result ids from the +result_ids+ argument to
  # the sum of all extra marks calculated for that result.
  #
  # If the +max_mark+ value is nil, its value will be determined dynamically
  # based on the max_mark value of the associated assignment.
  # However, passing the +max_mark+ value explicitly is more efficient if we are
  # repeatedly calling this method where the max_mark doesn't change, such as when
  # all the results are associated with the same assignment.
  #
  # +user_visibility+ is passed to the Assignment.max_mark method to determine the
  # max_mark value only if the +max_mark+ argument is nil.
  def self.get_total_extra_marks(result_ids, max_mark: nil, user_visibility: :ta_visible, subtotals: nil)
    result_data = Result.joins(:extra_marks, submission: [grouping: :assignment])
                        .where(id: result_ids)
                        .pluck(:id, :extra_mark, :unit, 'assessments.id')
    subtotals ||= Result.get_subtotals(result_ids, user_visibility: user_visibility)
    extra_marks_hash = Hash.new { |h, k| h[k] = nil }
    max_mark_hash = {}
    result_data.each do |id, extra_mark, unit, assessment_id|
      if extra_marks_hash[id].nil?
        extra_marks_hash[id] = 0
      end
      if unit == ExtraMark::POINTS
        extra_marks_hash[id] += extra_mark.round(2)
      elsif unit == ExtraMark::PERCENTAGE
        if max_mark
          assignment_max_mark = max_mark
        else
          max_mark_hash[assessment_id] ||= Assignment.find(assessment_id)&.max_mark(user_visibility)
          assignment_max_mark = max_mark_hash[assessment_id]
        end
        extra_marks_hash[id] += (extra_mark * assignment_max_mark / 100).round(2)
      elsif unit == ExtraMark::PERCENTAGE_OF_SCORE
        marks_earned = subtotals[id] || 0
        extra_marks_hash[id] += (extra_mark * marks_earned / 100).round(2)
      end
    end
    extra_marks_hash
  end

  def copy_grading_data(old_result)
    return if old_result.blank?

    self.marks.destroy_all

    self.update(overall_comment: old_result.overall_comment,
                remark_request_submitted_at: old_result.remark_request_submitted_at)

    old_result.marks.each do |mark|
      mark_dup = mark.dup
      mark_dup.update!(result_id: self.id)
    end

    old_result.annotations.each do |annotation|
      # annotations are associated with files; if a file for an annotation doesn't exist
      # we just skip adding this annotation to the new result
      annotation_filename = annotation.submission_file.filename
      annotation_path = annotation.submission_file.path
      new_submission_file = self.submission.submission_files.find_by(filename: annotation_filename,
                                                                     path: annotation_path)

      next if new_submission_file.nil?

      annotation_dup = annotation.dup
      annotation_dup.update!(result_id: self.id, submission_file_id: new_submission_file.id)
    end

    # NOTE: We are only copying point-based extra marks (which were manually
    # added to the old result). Percentage-based extra marks are added at the
    # instructor's discretion on newly-collected submissions, and therefore would
    # be submission-specific.
    old_result.extra_marks.where(unit: 'points').find_each do |extra_mark|
      extra_mark_dup = extra_mark.dup
      extra_mark_dup.update!(result_id: self.id)
    end
  end

  # un-releases the result
  def unrelease_results
    self.released_to_students = false
    self.save
  end

  def mark_as_partial
    return if self.released_to_students
    self.marking_state = Result::MARKING_STATES[:incomplete]
    self.save
  end

  def is_a_review?
    peer_reviews.exists?
  end

  def is_review_for?(user, assignment)
    grouping = user.grouping_for(assignment.id)
    pr = PeerReview.find_by(result_id: self.id)
    !pr.nil? && submission.grouping == grouping
  end

  def create_marks
    assignment = self.submission.assignment
    assignment.ta_criteria.each do |criterion|
      criterion.marks.find_or_create_by(result_id: id)
    end
  end

  # Returns a hash of all marks for this result.
  # TODO: make it include extra marks as well.
  def mark_hash
    marks.pluck_to_hash(:criterion_id, :mark, :override).index_by { |x| x[:criterion_id] }
  end

  def view_token_expired?
    !self.view_token_expiry.nil? && Time.current >= self.view_token_expiry
  end

  # Generate a PDF report for this result.
  # Currently only supports PDF submission file (all other submission files are skipped).
  def generate_print_pdf
    marks = self.mark_hash
    extra_marks = self.extra_marks
    total_mark = self.get_total_mark
    overall_comment = self.overall_comment
    submission = self.submission
    grouping = submission.grouping
    assignment = grouping.assignment

    # Make folder for temporary files
    workdir = "tmp/print/#{self.id}"
    FileUtils.mkdir_p(workdir)

    # Constants used for PDF generation
    logo_width = 80
    line_space = 12
    annotation_size = 20

    # Generate front page
    Prawn::Document.generate("#{workdir}/front.pdf") do
      # Add MarkUs logo
      image Rails.root.join('app/assets/images/markus_logo_big.png'),
            at: [bounds.width - logo_width, bounds.height],
            width: logo_width

      font_families.update(
        'Open Sans' => {
          normal: Rails.root.join('vendor/assets/stylesheets/fonts/OpenSansEmoji.ttf'),
          bold: Rails.root.join('vendor/assets/stylesheets/fonts/OpenSans-Bold.ttf')
        }
      )
      font 'Open Sans'

      # Title
      formatted_text [{
        text: "#{assignment.short_identifier}: #{assignment.description}", size: 20, styles: [:bold]
      }]
      move_down line_space

      # Group members
      grouping.accepted_students.includes(:user).find_each do |student|
        text "#{student.user_name} - #{student.first_name} #{student.last_name}"
      end
      move_down line_space

      # Marks
      assignment.ta_criteria.order(:position).find_each do |criterion|
        mark = marks.dig(criterion.id, :mark)
        if criterion.is_a? RubricCriterion
          formatted_text [{ text: "#{criterion.name}:", styles: [:bold] }]
          indent(10) do
            criterion.levels.order(:mark).find_each do |level|
              styles = level.mark == mark ? [:bold] : [:normal]
              formatted_text [{
                text: "• #{level.mark} / #{criterion.max_mark} #{level.name}: #{level.description}",
                styles: styles
              }]
            end
          end
        else
          formatted_text [{
            text: "#{criterion.name}: #{mark || '-'} / #{criterion.max_mark}",
            styles: [:bold]
          }]
          text criterion.description if criterion.description.present?
        end
      end

      extra_marks.each do |extra_mark|
        text "#{extra_mark.description}: #{extra_mark.extra_mark}#{extra_mark.unit == 'percentage' ? '%' : ''}"
      end
      move_down line_space

      formatted_text [{ text: "#{I18n.t('results.total_mark')}: #{total_mark} / #{assignment.max_mark}",
                        styles: [:bold] }]
      move_down line_space

      # Annotations and overall comments
      formatted_text [{ text: Annotation.model_name.human.pluralize, styles: [:bold] }]
      submission.annotations.order(:annotation_number).includes(:annotation_text).each do |annotation|
        text "#{annotation.annotation_number}. #{annotation.annotation_text.content}"
      end
      move_down line_space

      formatted_text [{ text: Result.human_attribute_name(:overall_comment), styles: [:bold] }]
      if overall_comment.present?
        text overall_comment
      else
        text I18n.t(:not_applicable)
      end
    end

    # Copy all PDF submission files to workspace
    input_files = submission.submission_files.where("filename LIKE '%.pdf'").order(:path, :filename)
    grouping.access_repo do |repo|
      input_files.each do |sf|
        contents = sf.retrieve_file(repo: repo)
        FileUtils.mkdir_p(File.join(workdir, sf.path))
        f = File.open(File.join(workdir, sf.path, sf.filename), 'wb')
        f.write(contents)
        f.close
      end
    end

    combined_pdf = CombinePDF.new
    # Simultaneouly do two things:
    # 1. Generate combined_pdf, a concatenation of all PDF submission files
    # 2. Generate annotations.pdf, a PDF containing only markers for annotations.
    #    These will be overlaid onto combined_pdf.
    Prawn::Document.generate("#{workdir}/annotations.pdf", skip_page_creation: true) do
      total_num_pages = 0
      input_files.each do |input_file|
        # Process the submission file
        input_pdf = CombinePDF.load(File.join(workdir, input_file.path, input_file.filename))
        combined_pdf << input_pdf

        num_pages = input_pdf.pages.size
        num_pages.times do
          start_new_page
        end

        # Create markers for the annotations.
        # TODO: remove where clause after investigating how PDF annotations might have a nil page attribute
        input_file.annotations.where.not(page: nil).order(:annotation_number).each do |annotation|
          go_to_page(total_num_pages + annotation.page)
          width, height = bounds.width, bounds.height
          x1, y1 = annotation.x1 / 1.0e5 * width, annotation.y1 / 1.0e5 * height

          float do
            transparent(0.5) do
              fill_color 'AAAAAA'
              fill_rectangle([x1, height - y1], annotation_size, annotation_size)
            end

            bounding_box([x1, height - y1], width: annotation_size, height: annotation_size) do
              move_down 5
              text annotation.annotation_number.to_s, color: '000000', align: :center
            end
          end
        end

        total_num_pages += num_pages
      end
    end

    # Combine annotations and submission files
    annotations_pdf = CombinePDF.load("#{workdir}/annotations.pdf")
    combined_pdf.pages.zip(annotations_pdf.pages) do |combined_page, annotation_page|
      combined_page.fix_rotation  # Fix rotation metadata, useful for scanned pages
      combined_page << annotation_page
    end

    input_files = submission.submission_files.where("filename LIKE '%.ipynb'").order(:path, :filename)
    grouping.access_repo do |repo|
      input_files.each do |sf|
        contents = sf.retrieve_file(repo: repo)
        tmp_path = File.join(workdir, 'tmp_file.pdf')
        FileUtils.rm_rf(tmp_path)
        args = [
          Rails.application.config.python,
          '-m', 'nbconvert',
          '--to', 'webpdf',
          '--stdin',
          '--output', File.join(workdir, File.basename(tmp_path.to_s, '.pdf'))  # Can't include the .pdf extension
        ]
        _stdout, stderr, status = Open3.capture3(*args, stdin_data: contents)
        if status.success?
          input_pdf = CombinePDF.load(tmp_path)
          combined_pdf << input_pdf
        else
          raise stderr
        end
      end
    end

    # Finally, insert cover page at the front
    combined_pdf >> CombinePDF.load("#{workdir}/front.pdf")

    # Delete old files
    FileUtils.rm_rf(workdir)
    combined_pdf
  end

  # Generate a filename to be used for the printed PDF.
  # For individual submissions, we use the form "{id_number} - {FAMILY NAME}, {Given Name} ({username}).pdf".
  # This is the form requested by the University of Toronto Arts & Science Exams Office (for final exams).
  # For group submissions, we use the form "{group name}.pdf"
  def print_pdf_filename
    if submission.grouping.accepted_students.size == 1
      student = submission.grouping.accepted_students.first.user
      "#{student.id_number} - #{student.last_name.upcase}, #{student.first_name} (#{student.user_name}).pdf"
    else
      members = submission.grouping.accepted_students.includes(:user).map { |s| s.user.user_name }.sort
      if members.empty?
        "#{submission.grouping.group.group_name}.pdf"
      else
        "#{submission.grouping.group.group_name} (#{members.join(', ')}).pdf"
      end
    end
  end

  private

  # Do not allow the marking state to be changed to incomplete if the result is released
  def check_for_released
    if released_to_students && marking_state_changed?(to: Result::MARKING_STATES[:incomplete])
      errors.add(:base, I18n.t('results.marks_released'))
      throw(:abort)
    end
    true
  end

  def check_for_nil_marks(user_visibility = :ta_visible)
    # This check is only required when the marking state is being changed to complete.
    return true unless marking_state_changed?(to: Result::MARKING_STATES[:complete])

    # peer review result is a special case because when saving a pr result
    # we can't pass in a parameter to the before_save filter, so we need
    # to manually determine the visibility. If it's a pr result, we know we
    # want the peer-visible criteria
    if is_a_review?
      visibility = :peer_visible
      assignment = submission.assignment.pr_assignment
    else
      visibility = user_visibility
      assignment = submission.assignment
    end

    criteria = assignment.criteria.where(visibility => true).ids
    nil_marks = false
    num_marks = 0
    marks.each do |mark|
      if criteria.member? mark.criterion_id
        num_marks += 1
        if mark.mark.nil?
          nil_marks = true
          break
        end
      end
    end

    if nil_marks || num_marks < criteria.count
      errors.add(:base, I18n.t('results.criterion_incomplete_error'))
      throw(:abort)
    end
    true
  end
end
