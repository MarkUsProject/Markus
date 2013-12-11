require 'will_paginate'

=begin How to Use the Grades Entry Form Pagination Helper
hash requires:
  :model              * the type of data that needs pagination
  :per_pages          * an array of integers, each integer representing
                        a selection of pagination size for the user
  :filters            * a list of possible filters that can be applied
                        to the data of type :model
    a name for each filter
      :display        * the text the user sees
      :proc => lambda * the processing done to each instance of the :model
  :sorts
    for each sort
    "name"            * the string that will appear in the URL of a GET
                        or AJAX request
      => lambda       * the lambda expression that handles the sorting
=end
module GradeEntryFormsPaginationHelper
  # For the hash that's passed to handle_ap_event, these are the required
  # fields.
  AP_REQUIRED_KEYS = [:model, :filters]
  AP_DEFAULT_PER_PAGE = 30
  AP_DEFAULT_PAGE = 1

  def handle_paginate_event(hash, object_hash, params)
    # First, let's make sure we have the required fields.
    # I'll take the keys from the hash, and difference it from
    # the AP_REQUIRED_FIELDS.  If there are any symbols left over
    # in the difference, the hash wasn't complete, and we should bail out.
    if (AP_REQUIRED_KEYS - hash.keys).size > 0
     # Fail loud, fail proud
      raise 'handle_paginate_event received an incomplete parameter hash'
    end
    # Ok, we have everything we need, let's get to work
    filter = params[:filter]
    desc = params[:desc]
    sorts = hash[:sorts]
    filters = hash[:filters]
    unless filters.include?(filter)
      raise "Could not find filter #{filter}"
    end
    items = get_filtered_items(hash, filter, params[:sort_by], desc)
    if params[:per_page].blank?
      params[:per_page] = AP_DEFAULT_PER_PAGE
    end
    if params[:page].blank?
      params[:page] = AP_DEFAULT_PAGE
    end

    return items.paginate(:per_page => params[:per_page], :page => params[:page]).clone, items.size

  end

  def get_filters(params)
    result = {}
    params[:filters].each do |filter_key, filter|
      result[filter[:display]] = filter_key
    end
    result
  end

  def get_filtered_items(hash, filter, sort_by, desc)
    if desc.present? && desc == 'true'
      order = 'DESC'
    else
      order = 'ASC'
    end

    hash[:filters][filter][:proc].call(sort_by, order, current_user)
  end

  # Given two last names, construct an alphabetical category for pagination.
  # eg. If the input is "Albert" and "Auric", return "Al" and "Au".
  def construct_alpha_category(name1, name2, alpha_categories, i)
    sameSoFar = true
    index = 0
    length_of_shorter_name = [name1.length, name2.length].min

    # Attempt to find the first character that differs
    while sameSoFar && (index < length_of_shorter_name)
      char1 = name1[index].chr
      char2 = name2[index].chr

      sameSoFar = (char1 == char2)
      index += 1
    end

    # Form the category name
    if sameSoFar and (index < name1.length)
      # There is at least one character remaining in the first name
      alpha_categories[i] << name1[0,index+1]
      alpha_categories[i+1] << name2[0, index]
    elsif sameSoFar and (index < name2.length)
      # There is at least one character remaining in the second name
      alpha_categories[i] << name1[0,index]
      alpha_categories[i+1] << name2[0, index+1]
    else
      alpha_categories[i] << name1[0, index]
      alpha_categories[i+1] << name2[0, index]
    end

    alpha_categories
  end

  # An algorithm for determining the category names for alphabetical pagination
  def alpha_paginate(all_grade_entry_students, per_page, sort_by)
    total_pages = (all_grade_entry_students.count / per_page.to_f).ceil
    alpha_pagination = []

    if total_pages == 0
      return alpha_pagination
    end

    alpha_categories = Array.new(2 * total_pages){[]}

    i = 0
    (1..(total_pages)).each do |page|
      grade_entry_students1 = all_grade_entry_students.paginate(:per_page => per_page, :page => page)

      # To figure out the category names, we need to keep track of the first and last students
      # on a particular page and the first student on the next page. For example, if these
      # names are "Alwyn, Anderson, and Antheil", the category for this page would be:
      # "Al-And".
      first_student = get_name_to_paginate(grade_entry_students1.first, sort_by)
      last_student = get_name_to_paginate(grade_entry_students1.last, sort_by)

      # Update the possible categories
      alpha_categories = self.construct_alpha_category(first_student, last_student,
                                                       alpha_categories, i)
      unless page == total_pages
        grade_entry_students2 = all_grade_entry_students.paginate(:per_page => per_page, :page => page+1)
        next_student = get_name_to_paginate(grade_entry_students2.first, sort_by)
        alpha_categories = self.construct_alpha_category(last_student, next_student,
                                                         alpha_categories, i+1)
      end

      i += 2
    end

    # We can now form the category names
    j=0
    (1..total_pages).each do |i|
      alpha_pagination << (alpha_categories[j].max + '-' + alpha_categories[j+1].max)
      j += 2
    end

    return alpha_pagination
  end

  def get_name_to_paginate(grade_entry_student, sort_by)
    if sort_by == 'user_name'
      return grade_entry_student.user_name || '-'
    elsif
      sort_by == 'last_name'
      return grade_entry_student.last_name || '-'
    elsif
      sort_by == 'first_name'
      return grade_entry_student.first_name || '-'
    elsif
      sort_by == 'section'
      section = grade_entry_student.section
      if section
        return section.name + ':' + grade_entry_student.user_name
      end
      return '~:' + grade_entry_student.user_name
    end
  end

end

