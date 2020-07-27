describe JobMessagesController do
  shared_examples 'job messages' do
    describe '.get' do
      let(:job) { ApplicationJob.perform_later }
      let(:status) { ActiveJob::Status.get(job.job_id) }
      context 'when a job has been enqueued' do
        before :each do
          status[:status] = status_type
          params = { job_id: job.job_id }
          get_as user, :get, params: params, session: params
        end
        after :each do
          flash.discard
        end
        context 'when the job failed' do
          let(:status_type) { :failed }
          it 'should flash an error message' do
            expect(flash[:error]).not_to be_nil
          end
          it 'should set the session[:job_id] to nil' do
            expect(request.session[:job_id]).to be_nil
          end
          it 'should remove any progress flash messages' do
            expect(response.headers['X-Message-Discard']).to include 'notice'
          end
        end
        context 'when the job completed successfully' do
          let(:status_type) { :completed }
          it 'should flash an success message' do
            expect(flash[:success]).not_to be_nil
          end
          it 'should set the session[:job_id] to nil' do
            expect(request.session[:job_id]).to be_nil
          end
          it 'should remove any progress flash messages' do
            expect(response.headers['X-Message-Discard']).to include 'notice'
          end
        end
        context 'when the job is queued' do
          let(:status_type) { :queued }
          it 'should flash a notice message' do
            expect(flash[:notice]).to include "<p>#{I18n.t('poll_job.queued')}</p>"
          end
          it 'should not set the session[:job_id] to nil' do
            expect(request.session[:job_id]).to eq job.job_id
          end
          it 'should not remove any progress flash messages' do
            expect(response.headers['X-Message-Discard']).to be_nil
          end
        end
        context 'when the job is working' do
          let(:status_type) { :working }
          it 'should flash a notice message' do
            expect(flash[:notice]).to include "<p>#{ApplicationJob.show_status(status)}</p>"
          end
          it 'should not set the session[:job_id] to nil' do
            expect(request.session[:job_id]).to eq job.job_id
          end
          it 'should not remove any progress flash messages' do
            expect(response.headers['X-Message-Discard']).to be_nil
          end
        end
      end
      context 'when no job has been enqueued' do
        before :each do
          get_as user, :get, params: { job_id: 'a' }
        end
        it 'should flash an error message' do
          expect(flash[:error]).not_to be_nil
        end
        it 'should set the session[:job_id] to nil' do
          expect(request.session[:job_id]).to be_nil
        end
      end
    end
  end
  context 'as an admin' do
    let(:user) { create :admin }
    it_behaves_like 'job messages'
  end
  context 'as a grader' do
    let(:user) { create :ta }
    it_behaves_like 'job messages'
  end
end
