module GroupsHelper
  # Gets information needed to display students
  # in the table on the front-end. Returns
  # an array of hashes.
  def get_students_table_info
    students = Student.all
    student_memberships = StudentMembership
                          .includes(:user)
                          .where(grouping_id: @assignment.groupings)

    students_in_assignment = student_memberships.map do |membership|
      membership.user
    end

    students.map do |student|
      s = student.attributes
      s['assigned'] = students_in_assignment.include?(student)
      s
    end
  end

  # Run several checks on the data from an uploaded file in order to determine whether to proceed with
  # creating groups based on that file or not. Returns true if any errors are found and displays flash
  # messages describing each error unless +suppress_flash+ is true.
  def validate_csv_upload_file(assignment, data, suppress_flash: false)
    errors = Hash.new { |h, k| h[k] = [] }
    group_names, repo_names, students = Set.new, Set.new, Set.new
    assignment_id = assignment.id

    data.each do |group_name, repo_name, *members|
      errors[:bad_cell].concat [group_name, repo_name, *members].select(&:blank?)
      errors[:dup_groups] << group_name if group_names.member?(group_name)
      errors[:dup_repos] << repo_name if repo_names.member?(repo_name)
      errors[:dup_members].concat students.intersection(members).to_a
      errors[:dup_members].concat members.group_by(&:itself).values.select { |v| v.size > 1 }.map(&:first)
      group_names << group_name
      repo_names << repo_name
      students.merge members
    end
    errors[:bad_repo] += find_bad_repo_query(data).pluck(:group_name)
    errors[:inconsistent_group_memberships] += find_bad_group_memberships(data).map(&:first)
    errors[:bad_students] = find_bad_students(data)
    errors[:membership_exists] += find_bad_grouping_memberships_query(data, assignment_id).pluck('users.user_name')
    flash_csv_upload_file_validation_errors(errors) unless suppress_flash
    errors.values.flatten.empty?
  end

  private

  # Display flash message based errors contained in the +errors+ hash
  def flash_csv_upload_file_validation_errors(errors)
    unless errors[:bad_cell].empty?
      flash_now :error, I18n.t('csv.bad_cell',
                               bad_cells: errors[:bad_cell].map { |c| "'#{c}'" }.join(', '))
    end
    unless errors[:dup_groups].empty?
      flash_now :error, I18n.t('csv.duplicate_group_name',
                               group_names: errors[:dup_groups].join(', '))
    end
    unless errors[:dup_repos].empty?
      flash_now :error, I18n.t('csv.duplicate_repo_name',
                               repo_names: errors[:dup_repos].join(', '))
    end
    unless errors[:dup_members].empty?
      flash_now :error, I18n.t('csv.duplicate_membership_name',
                               member_names: errors[:dup_members].join(', '))
    end
    unless errors[:bad_repo].empty?
      flash_now :error, I18n.t('csv.bad_repo_warning',
                               group_names: errors[:bad_repo].join(', '))
    end
    unless errors[:inconsistent_group_memberships].empty?
      flash_now :error, I18n.t('csv.bad_membership_warning',
                               group_names: errors[:inconsistent_group_memberships].join(', '))
    end
    unless errors[:bad_students].empty?
      flash_now :error, I18n.t('csv.bad_students',
                               student_names: errors[:bad_students].join(', '))
    end
    unless errors[:membership_exists].empty?
      flash_now :error, I18n.t('csv.memberships_exist',
                               student_names: errors[:membership_exists].join(', '))
    end
  end

  # Return a query that can be used to select all groups that appear in +data+ with the
  # same group_name but with a different repo_name
  def find_bad_repo_query(data, query: nil)
    return query if data.empty?

    data = data.dup if query.nil?
    group_name, repo_name = data.shift
    query_update = Group.where(group_name: group_name).where.not(repo_name: repo_name)
    query_update = query.or(query_update) unless query.nil?
    find_bad_repo_query(data, query: query_update)
  end

  # Return a query that can be used to select all groups that appear in +data+ that have
  # a member that is already a member of a grouping for that assignment
  def find_bad_grouping_memberships_query(data, assignment_id, query: nil)
    return query if data.empty?

    data = data.dup if query.nil?
    group_name, _, *memberships = data.shift
    valid_statuses = [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]
    query_update = Group.joins(groupings: [student_memberships: :user])
                        .where('groupings.assignment_id': assignment_id)
                        .where('memberships.membership_status': valid_statuses)
                        .where('users.user_name': memberships)
                        .where.not(group_name: group_name)
    query_update = query.or(query_update) unless query.nil?
    find_bad_grouping_memberships_query(data, assignment_id, query: query_update)
  end

  # Return a list of rows from +data+ where the group_name is a group that exists but the
  # members of the group are different from the memberships in +data+
  def find_bad_group_memberships(data)
    valid_statuses = [StudentMembership::STATUSES[:accepted], StudentMembership::STATUSES[:inviter]]
    group_memberships = Group.joins(groupings: [student_memberships: :user])
                             .where('memberships.membership_status': valid_statuses)
                             .where(group_name: data.map(&:first))
                             .pluck(:group_name, 'users.user_name')
                             .group_by(&:first)
                             .transform_values { |v| Set.new(v.map(&:last)) }
    data.select do |group_name, _repo_name, *memberships|
      if (existant_memberships = group_memberships[group_name])
        existant_memberships != Set.new(memberships)
      end
    end
  end

  # Return a list of student user_names from the memberships in +data+ where the
  # student in question does not exist
  def find_bad_students(data)
    students = Set.new(Student.where(hidden: false).all.pluck(:user_name))
    data.map { |_, _, *memberships| memberships }.flatten.reject { |student| students.include?(student) }
  end
end
