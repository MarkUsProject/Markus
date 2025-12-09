describe OcrMatchService do
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:exam_template) { create(:exam_template_midterm, assignment: assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }

  # Create students with known attributes for testing
  let!(:student1) do
    create(:student, user: create(:end_user, user_name: 'student001', id_number: '1234567'), course: course)
  end
  let(:student2) do
    create(:student, user: create(:end_user, user_name: 'student002', id_number: '1234568'), course: course)
  end
  let(:student3) do
    # Similar username
    create(:student, user: create(:end_user, user_name: 'studen001', id_number: '1234567890'), course: course)
  end

  before do
    # Clear Redis before each test
    redis.del("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
    redis.del("ocr_matches:exam_template:#{exam_template.id}:unmatched")
  end

  after do
    # Clean up Redis after each test
    redis.del("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
    redis.del("ocr_matches:exam_template:#{exam_template.id}:unmatched")
  end

  describe '.store_match' do
    context 'when auto-match succeeded' do
      it 'stores the OCR match data in Redis' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: true,
          student_id: student1.id
        )

        stored_data = redis.get("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
        expect(stored_data).not_to be_nil

        parsed_data = JSON.parse(stored_data, symbolize_names: true)
        expect(parsed_data[:parsed_value]).to eq('1234567')
        expect(parsed_data[:field_type]).to eq('id_number')
        expect(parsed_data[:matched]).to be true
        expect(parsed_data[:matched_student_id]).to eq(student1.id)
        expect(parsed_data[:timestamp]).to be_present
      end

      it 'sets the TTL on the Redis key' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: true,
          student_id: student1.id
        )

        ttl = redis.ttl("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
        expect(ttl).to be > 0
        expect(ttl).to be <= OcrMatchService::TTL
      end

      it 'does not add grouping to unmatched set' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: true,
          student_id: student1.id
        )

        unmatched = redis.smembers("ocr_matches:exam_template:#{exam_template.id}:unmatched")
        expect(unmatched).not_to include(grouping.id.to_s)
      end
    end

    context 'when auto-match failed' do
      it 'stores the OCR match data with matched=false' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'invalid123',
          'id_number',
          matched: false
        )

        stored_data = redis.get("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
        parsed_data = JSON.parse(stored_data, symbolize_names: true)

        expect(parsed_data[:parsed_value]).to eq('invalid123')
        expect(parsed_data[:matched]).to be false
        expect(parsed_data[:matched_student_id]).to be_nil
      end

      it 'adds grouping to unmatched set' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'invalid123',
          'id_number',
          matched: false
        )

        unmatched = redis.smembers("ocr_matches:exam_template:#{exam_template.id}:unmatched")
        expect(unmatched).to include(grouping.id.to_s)
      end

      it 'sets TTL on the unmatched set' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'invalid123',
          'id_number',
          matched: false
        )

        ttl = redis.ttl("ocr_matches:exam_template:#{exam_template.id}:unmatched")
        expect(ttl).to be > 0
        expect(ttl).to be <= OcrMatchService::TTL
      end
    end

    context 'with user_name field type' do
      it 'stores match data with user_name field type' do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'student001',
          'user_name',
          matched: true,
          student_id: student1.id
        )

        stored_data = redis.get("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
        parsed_data = JSON.parse(stored_data, symbolize_names: true)

        expect(parsed_data[:field_type]).to eq('user_name')
        expect(parsed_data[:parsed_value]).to eq('student001')
      end
    end
  end

  describe '.get_match' do
    context 'when match data exists' do
      before do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: true,
          student_id: student1.id
        )
      end

      it 'retrieves the stored OCR match data' do
        result = OcrMatchService.get_match(grouping.id, exam_template.id)

        expect(result).to be_a(Hash)
        expect(result[:parsed_value]).to eq('1234567')
        expect(result[:field_type]).to eq('id_number')
        expect(result[:matched]).to be true
        expect(result[:matched_student_id]).to eq(student1.id)
      end

      it 'returns symbolized keys' do
        result = OcrMatchService.get_match(grouping.id, exam_template.id)

        expect(result.keys).to all(be_a(Symbol))
      end
    end

    context 'when match data does not exist' do
      it 'returns nil' do
        result = OcrMatchService.get_match(grouping.id, exam_template.id)
        expect(result).to be_nil
      end
    end
  end

  describe '.get_suggestions' do
    context 'when OCR match data exists' do
      before do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'student001',
          'user_name',
          matched: false
        )
      end

      it 'returns student suggestions sorted by similarity' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        expect(suggestions).to be_an(Array)
        expect(suggestions).not_to be_empty
        expect(suggestions.first).to have_key(:student)
        expect(suggestions.first).to have_key(:similarity)
      end

      it 'returns exact match with similarity 1.0' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        exact_match = suggestions.find { |s| s[:student].user.user_name == 'student001' }
        expect(exact_match).to be_present
        expect(exact_match[:similarity]).to eq(1.0)
      end

      it 'returns suggestions sorted by similarity (highest first)' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        similarities = suggestions.pluck(:similarity)
        expect(similarities).to eq(similarities.sort.reverse)
      end

      it 'limits results to the specified limit' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id, limit: 2)

        expect(suggestions.length).to be <= 2
      end

      it 'includes close matches with high similarity' do
        # 'studen001' should be similar to 'student001'
        student3 # Ensure student3 is created
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        similar_match = suggestions.find { |s| s[:student].user.user_name == 'studen001' }
        expect(similar_match).to be_present
        expect(similar_match[:similarity]).to be > 0.8
      end

      it 'defaults to limit of 5' do
        # Create more students to test default limit
        6.times do |i|
          create(:student, user: create(:end_user, user_name: "student#{100 + i}"), course: course)
        end

        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)
        expect(suggestions.length).to be <= 5
      end
    end

    context 'when matching by id_number' do
      before do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: false
        )
      end

      it 'matches students by id_number' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        exact_match = suggestions.find { |s| s[:student].user.id_number == '1234567' }
        expect(exact_match).to be_present
        expect(exact_match[:similarity]).to eq(1.0)
      end

      it 'finds similar id_numbers' do
        student2 # Ensure student2 is created
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        # '1234568' is very similar to '1234567'
        similar_match = suggestions.find { |s| s[:student].user.id_number == '1234568' }
        expect(similar_match).to be_present
        expect(similar_match[:similarity]).to be > 0.8
      end
    end

    context 'when OCR match data does not exist' do
      it 'returns empty array' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)
        expect(suggestions).to eq([])
      end
    end

    context 'when students have blank match values' do
      let!(:student_no_id) do
        create(:student, user: create(:end_user, user_name: 'student_no_id', id_number: nil), course: course)
      end

      before do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          '1234567',
          'id_number',
          matched: false
        )
      end

      it 'excludes students with blank match values' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        student_ids = suggestions.map { |s| s[:student].id }
        expect(student_ids).not_to include(student_no_id.id)
      end
    end

    context 'case insensitive matching' do
      before do
        OcrMatchService.store_match(
          grouping.id,
          exam_template.id,
          'STUDENT001',
          'user_name',
          matched: false
        )
      end

      it 'matches case-insensitively' do
        suggestions = OcrMatchService.get_suggestions(grouping.id, exam_template.id, course.id)

        exact_match = suggestions.find { |s| s[:student].user.user_name == 'student001' }
        expect(exact_match).to be_present
        expect(exact_match[:similarity]).to eq(1.0)
      end
    end
  end

  describe '.clear_match' do
    before do
      OcrMatchService.store_match(
        grouping.id,
        exam_template.id,
        'student001',
        'user_name',
        matched: false
      )
    end

    it 'removes the match data from Redis' do
      OcrMatchService.clear_match(grouping.id, exam_template.id)

      stored_data = redis.get("ocr_matches:exam_template:#{exam_template.id}:grouping:#{grouping.id}")
      expect(stored_data).to be_nil
    end

    it 'removes grouping from unmatched set' do
      OcrMatchService.clear_match(grouping.id, exam_template.id)

      unmatched = redis.smembers("ocr_matches:exam_template:#{exam_template.id}:unmatched")
      expect(unmatched).not_to include(grouping.id.to_s)
    end

    context 'when match data does not exist' do
      it 'does not raise an error' do
        another_grouping = create(:grouping, assignment: assignment)

        expect do
          OcrMatchService.clear_match(another_grouping.id, exam_template.id)
        end.not_to raise_error
      end
    end
  end

  describe 'private methods' do
    describe '.string_similarity' do
      it 'returns 1.0 for identical strings' do
        similarity = OcrMatchService.__send__(:string_similarity, 'test', 'test')
        expect(similarity).to eq(1.0)
      end

      it 'returns 1.0 for case-insensitive identical strings' do
        similarity = OcrMatchService.__send__(:string_similarity, 'Test', 'test')
        expect(similarity).to eq(1.0)
      end

      it 'returns 0.0 for completely different strings' do
        similarity = OcrMatchService.__send__(:string_similarity, 'abc', 'xyz')
        expect(similarity).to be < 0.5
      end

      it 'returns high similarity for similar strings' do
        similarity = OcrMatchService.__send__(:string_similarity, 'student', 'studen')
        expect(similarity).to be > 0.8
      end

      it 'handles whitespace correctly' do
        similarity = OcrMatchService.__send__(:string_similarity, ' test ', 'test')
        expect(similarity).to eq(1.0)
      end

      it 'returns 0.0 when first string is blank' do
        similarity = OcrMatchService.__send__(:string_similarity, '', 'test')
        expect(similarity).to eq(0.0)
      end

      it 'returns 0.0 when second string is blank' do
        similarity = OcrMatchService.__send__(:string_similarity, 'test', '')
        expect(similarity).to eq(0.0)
      end

      it 'returns 1.0 when both strings are blank (identical)' do
        similarity = OcrMatchService.__send__(:string_similarity, '', '')
        expect(similarity).to eq(1.0)
      end

      it 'handles nil values' do
        similarity = OcrMatchService.__send__(:string_similarity, nil, 'test')
        expect(similarity).to eq(0.0)

        similarity = OcrMatchService.__send__(:string_similarity, 'test', nil)
        expect(similarity).to eq(0.0)
      end

      it 'returns value between 0 and 1' do
        similarity = OcrMatchService.__send__(:string_similarity, 'student001', 'student002')
        expect(similarity).to be_between(0.0, 1.0).inclusive
      end
    end

    describe '.student_match_value' do
      it 'returns id_number for id_number field type' do
        value = OcrMatchService.__send__(:student_match_value, student1, 'id_number')
        expect(value).to eq(student1.user.id_number)
      end

      it 'returns user_name for user_name field type' do
        value = OcrMatchService.__send__(:student_match_value, student1, 'user_name')
        expect(value).to eq(student1.user.user_name)
      end

      it 'returns nil for unknown field type' do
        value = OcrMatchService.__send__(:student_match_value, student1, 'unknown')
        expect(value).to be_nil
      end
    end
  end
end
