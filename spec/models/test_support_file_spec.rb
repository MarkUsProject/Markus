describe TestSupportFile do
  it { is_expected.to belong_to(:assignment) }

  it { is_expected.to validate_presence_of :file_name }

  context 'test support file' do
    before(:each) do
      @asst = create(:assignment, section_due_dates_type: false, due_date: 2.days.from_now)
    end

    # create
    context 'A valid test support file' do
      context 'A valid test support file with description' do
        before {
          @support_file = TestSupportFile.create(
            assignment: @asst,
            file_name: 'input.txt',
            description: 'This is an input file')
        }
        it 'return true when a valid file is created' do
          expect(@support_file).to be_valid
          expect(@support_file.save).to be true
        end
      end

      context 'A valid test support file without description' do
        before {
          @support_file = TestSupportFile.create(
            assignment: @asst,
            file_name: 'actual_output.txt',
            description: '')
        }
        it 'return true when a valid file is created' do
          expect(@support_file).to be_valid
          expect(@support_file.save).to be true
        end
      end
    end

    # update
    context 'An invalid test support file' do
      context 'support file expected to be invalid when the file name is blank' do
        before {
          @invalid_support_file = TestSupportFile.create(
            description: 'This is an invalid support file',
            assignment: @asst,
            file_name: '   ')
        }
        it 'return false when the file_name is blank' do
          expect(@invalid_support_file).not_to be_valid
        end
      end

      context 'support file expected to be invalid when the description is nil' do
        before {
          @invalid_support_file = TestSupportFile.create(
            file_name: 'invalid',
            description: nil,
            assignment: @asst)
        }
        it 'return false when the description is nil' do
          expect(@invalid_support_file).not_to be_valid
        end
      end

      context 'support file expected to be invalid when the file name already exists in the same assignment' do
        before {
          @valid_support_file = TestSupportFile.create(
            file_name: 'valid',
            description: 'This is a valid support file',
            assignment_id: 1
          )
          @invalid_support_file = TestSupportFile.create(
            file_name: 'valid',
            description: nil,
            assignment: @asst,
            assignment_id: 1
          )
        }
        it 'return false when the file_name already exists' do
          expect(@invalid_support_file).not_to be_valid
        end
      end
    end

    # delete
    context 'MarkUs' do
      before {
        @support_file = TestSupportFile.create(
          assignment: @asst,
          file_name: 'input.txt',
          description: 'This is an input file')
      }
      it 'be able to delete a test support file' do
        expect(@support_file).to be_valid
        expect{@support_file.destroy}.to change {TestSupportFile.count}.by(-1)
      end
    end
  end
end
