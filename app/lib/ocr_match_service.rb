# Service for storing and retrieving OCR match data from Redis.
# Used to persist OCR parsing results for scanned exam assignments,
# enabling suggestions for manual student assignment.
class OcrMatchService
  # Time-to-live for OCR match data in Redis (30 days)
  TTL = 30.days.to_i

  class << self
    # Store an OCR match result in Redis
    def store_match(grouping_id, parsed_value, field_type, matched: false, student_id: nil)
      data = {
        parsed_value: parsed_value,
        field_type: field_type,
        timestamp: Time.current.iso8601,
        matched: matched,
        matched_student_id: student_id
      }

      redis.setex(match_key(grouping_id), TTL, data.to_json)

      # Add to unmatched set if not auto-matched
      unless matched
        redis.sadd(unmatched_set_key, grouping_id)
        redis.expire(unmatched_set_key, TTL)
      end
    end

    # Retrieve stored OCR match data for a grouping
    def get_match(grouping_id)
      data = redis.get(match_key(grouping_id))
      data ? JSON.parse(data, symbolize_names: true) : nil
    end

    # Get student suggestions based on stored OCR match using fuzzy matching
    # Only considers students not already assigned to a grouping for this assignment
    # Returns students meeting the similarity threshold (default 80%), limited to top matches (default 5)
    def get_suggestions(grouping_id, course_id, threshold: 0.8, limit: 5)
      match_data = get_match(grouping_id)
      return [] if match_data.nil?

      grouping = Grouping.find(grouping_id)
      assignment = grouping.assignment
      course = Course.find(course_id)

      # Get students who are not assigned to any grouping for this assignment
      assigned_student_ids = assignment.groupings
                                       .joins(:student_memberships)
                                       .pluck('memberships.role_id')
      students = course.students.includes(:user).where.not(id: assigned_student_ids)

      # Calculate similarity scores for each student
      suggestions = students.filter_map do |student|
        value_to_match = student_match_value(student, match_data[:field_type])
        next if value_to_match.blank?

        similarity = string_similarity(match_data[:parsed_value], value_to_match)
        next if similarity < threshold

        { student: student, similarity: similarity }
      end

      # Return top matches by similarity (highest first)
      suggestions.max_by(limit) { |s| s[:similarity] }
    end

    # Clear OCR match data after manual assignment
    def clear_match(grouping_id)
      redis.del(match_key(grouping_id))
      redis.srem(unmatched_set_key, grouping_id)
    end

    private

    def match_key(grouping_id)
      "ocr_matches:grouping:#{grouping_id}"
    end

    def unmatched_set_key
      'ocr_matches:unmatched'
    end

    def redis
      Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
    end

    # Get the value to match against based on field type
    def student_match_value(student, field_type)
      case field_type
      when 'id_number' then student.user.id_number
      when 'user_name' then student.user.user_name
      end
    end

    # Calculate similarity between two strings using Levenshtein distance
    # Returns a score between 0 and 1, where 1 is identical
    def string_similarity(str1, str2)
      return 1.0 if str1 == str2
      return 0.0 if str1.blank? || str2.blank?

      # Normalize strings for case-insensitive comparison
      s1 = str1.to_s.downcase.strip
      s2 = str2.to_s.downcase.strip
      return 1.0 if s1 == s2

      # Use Ruby's built-in Levenshtein distance calculation
      distance = DidYouMean::Levenshtein.distance(s1, s2)
      max_length = [s1.length, s2.length].max
      return 0.0 if max_length.zero?

      1.0 - (distance.to_f / max_length)
    end
  end
end
