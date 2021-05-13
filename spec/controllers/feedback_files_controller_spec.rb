describe FeedbackFilesController do
  let(:grouping) { create(:grouping_with_inviter_and_submission) }
  let(:feedback_file) { create(:feedback_file, submission: grouping.submissions.first) }
  let(:instructor_test_run_feedback_file) do
    grouping = create(:grouping_with_inviter_and_submission)
    test_run = create(:test_run, grouping: grouping)
    test_group_result = create(:test_group_result, test_run: test_run)
    create(:feedback_file_with_test_run, test_group_result: test_group_result)
  end

  let(:student_test_run_feedback_file) do
    grouping = create(:grouping_with_inviter_and_submission)
    test_run = create(:student_test_run, grouping: grouping)
    test_group_result = create(:test_group_result, test_run: test_run)
    create(:feedback_file_with_test_run, test_group_result: test_group_result)
  end

  describe '#show' do
    let(:admin) { create(:admin) }

    context 'when an admin' do
      context 'requests a feedback file associated with a submission' do
        it 'downloads the file contents' do
          get_as admin, :show, params: { id: feedback_file.id }

          expect(response).to have_http_status :success
          expect(response.body).to eq(feedback_file.file_content)
        end
      end

      context 'requests a feedback file associated with an instructor test run' do
        it 'downloads the file contents' do
          get_as admin, :show, params: { id: instructor_test_run_feedback_file.id }

          expect(response).to have_http_status :success
          expect(response.body).to eq(instructor_test_run_feedback_file.file_content)
        end
      end

      context 'requests a feedback file associated with a student test run' do
        it 'downloads the file contents' do
          get_as admin, :show, params: { id: student_test_run_feedback_file.id }

          expect(response).to have_http_status :success
          expect(response.body).to eq(student_test_run_feedback_file.file_content)
        end
      end
    end

    context 'when a TA' do
      let(:ta) { create(:ta) }

      context 'requests a feedback file associated with a submission' do
        context 'for a grouping they are not assigned' do
          it 'does not download the file contents' do
            get_as ta, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end

        context 'for a grouping they are assigned' do
          it 'downloads the file contents' do
            create(:ta_membership, user: ta, grouping: grouping)
            get_as ta, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :success
            expect(response.body).to eq(feedback_file.file_content)
          end
        end
      end

      context 'requests a feedback file associated with an instructor test run' do
        context 'for a grouping they are not assigned' do
          it 'does not download the file contents' do
            get_as ta, :show, params: { id: instructor_test_run_feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end

        context 'for a grouping they are assigned' do
          it 'downloads the file contents' do
            create(:ta_membership, user: ta, grouping: instructor_test_run_feedback_file.grouping)
            get_as ta, :show, params: { id: instructor_test_run_feedback_file.id }

            expect(response).to have_http_status :success
            expect(response.body).to eq(instructor_test_run_feedback_file.file_content)
          end
        end
      end

      context 'requests a feedback file associated with a student test run' do
        context 'for a grouping they are not assigned' do
          it 'does not download the file contents' do
            get_as ta, :show, params: { id: student_test_run_feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end

        context 'for a grouping they are assigned' do
          it 'downloads the file contents' do
            create(:ta_membership, user: ta, grouping: student_test_run_feedback_file.grouping)
            get_as ta, :show, params: { id: student_test_run_feedback_file.id }

            expect(response).to have_http_status :success
            expect(response.body).to eq(student_test_run_feedback_file.file_content)
          end
        end
      end
    end

    context 'when a student' do
      context 'requests a feedback file associated with a submission' do
        context 'when it is their submission and the result is released' do
          it 'downloads the file contents' do
            feedback_file.grouping.current_result.update!(released_to_students: true)

            get_as feedback_file.grouping.students.first, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :success
            expect(response.body).to eq(feedback_file.file_content)
          end
        end

        context 'when it is their submission and the result is not released' do
          it 'does not download the file contents' do
            get_as feedback_file.grouping.students.first, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end

        context 'when it is not their submission and the result is released' do
          it 'does not download the file contents' do
            feedback_file.grouping.current_result.update!(released_to_students: true)
            new_student = create(:student)
            get_as new_student, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end

        context 'when it is not their submission and the result is not released' do
          it 'does not download the file contents' do
            new_student = create(:student)
            get_as new_student, :show, params: { id: feedback_file.id }

            expect(response).to have_http_status :forbidden
          end
        end
      end
    end

    context 'requests a feedback file associated with an instructor test run' do
      context 'when it is their submission and the result is released' do
        it 'downloads the file contents' do
          instructor_test_run_feedback_file.grouping.current_result.update!(released_to_students: true)

          get_as instructor_test_run_feedback_file.grouping.students.first, :show,
                 params: { id: instructor_test_run_feedback_file.id }

          expect(response).to have_http_status :success
          expect(response.body).to eq(instructor_test_run_feedback_file.file_content)
        end
      end

      context 'when it is their submission and the result is not released' do
        it 'does not download the file contents' do
          get_as instructor_test_run_feedback_file.grouping.students.first, :show,
                 params: { id: instructor_test_run_feedback_file.id }

          expect(response).to have_http_status :forbidden
        end
      end

      context 'when it is not their submission and the result is released' do
        it 'does not download the file contents' do
          instructor_test_run_feedback_file.grouping.current_result.update!(released_to_students: true)
          new_student = create(:student)
          get_as new_student, :show, params: { id: instructor_test_run_feedback_file.id }

          expect(response).to have_http_status :forbidden
        end
      end

      context 'when it is not their submission and the result is not released' do
        it 'does not download the file contents' do
          new_student = create(:student)
          get_as new_student, :show, params: { id: instructor_test_run_feedback_file.id }

          expect(response).to have_http_status :forbidden
        end
      end
    end

    context 'requests a feedback file associated with a student test run' do
      context 'when it is their grouping' do
        it 'downloads the file contents' do
          get_as student_test_run_feedback_file.grouping.students.first, :show,
                 params: { id: student_test_run_feedback_file.id }

          expect(response).to have_http_status :success
          expect(response.body).to eq(student_test_run_feedback_file.file_content)
        end
      end

      context 'when it is not their grouping' do
        it 'does not download the file contents' do
          new_student = create(:student)
          get_as new_student, :show, params: { id: student_test_run_feedback_file.id }

          expect(response).to have_http_status :forbidden
        end
      end
    end
  end
end
