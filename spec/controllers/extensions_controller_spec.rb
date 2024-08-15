describe ExtensionsController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  describe 'as an instructor' do
    let(:instructor) { create(:instructor) }
    let(:grouping) { create(:grouping) }
    let(:course) { instructor.course }

    describe '#update' do
      let(:extension) { create(:extension, grouping: grouping) }
      let(:params) do
        parts = extension.to_parts
        {
          id: extension.id,
          course_id: course.id,
          weeks: parts[:weeks] + 1,
          days: parts[:days] + 1,
          hours: parts[:hours] + 1,
          note: 'something',
          penalty: true
        }
      end

      it 'should not create a new extension' do
        extension # make sure the object is created before the call
        expect { put_as instructor, :update, params: params }.not_to(change { Extension.count })
      end

      it 'should flash a message on success' do
        expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:success, anything)
        put_as instructor, :update, params: params
      end

      it 'should flash a message on error' do
        expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:error, anything)
        params[:weeks] = 0
        params[:days] = 0
        params[:hours] = 0
        put_as instructor, :update, params: params
      end

      describe 'it should update the attibute:' do
        before do
          put_as instructor, :update, params: params
          extension.reload
        end

        it 'time_delta' do
          expected_duration = Extension::PARTS.sum { |part| params[part].to_i.public_send(part) }
          expect(extension.time_delta).to eq(expected_duration)
        end

        it 'note' do
          expect(extension.note).to eq(params[:note])
        end

        it 'apply_penalty' do
          expect(extension.apply_penalty).to eq(params[:penalty])
        end
      end
    end

    describe '#create' do
      let(:extension) { Extension.find_by(grouping_id: grouping.id) }
      let(:params) do
        {
          grouping_id: grouping.id,
          course_id: course.id,
          weeks: rand(1..10),
          days: rand(1..10),
          hours: rand(1..10),
          note: 'something',
          penalty: true
        }
      end

      it 'should create a new extension' do
        expect { post_as instructor, :create, params: params }.to change { Extension.count }.by(1)
      end

      it 'should flash a message on success' do
        expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:success, anything)
        post_as instructor, :create, params: params
      end

      it 'should flash a message on error' do
        expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:error, anything)
        params[:grouping_id] = nil
        post_as instructor, :create, params: params
      end

      describe 'it should update the attibute:' do
        before do
          post_as instructor, :create, params: params
          extension.reload
        end

        it 'time_delta' do
          expected_duration = Extension::PARTS.sum { |part| params[part].to_i.public_send(part) }
          expect(extension.time_delta.to_i).to eq(expected_duration)
        end

        it 'note' do
          expect(extension.note).to eq(params[:note])
        end

        it 'apply_penalty' do
          expect(extension.apply_penalty).to eq(params[:penalty])
        end
      end
    end

    describe '#destroy' do
      context 'and the extension exists' do
        let(:extension) { create(:extension, grouping: grouping) }

        it 'should delete the extension' do
          extension # make sure the object is created before the call
          expect do
            delete_as instructor, :destroy, params: { course_id: course.id, id: extension.id }
          end.to change { Extension.count }.by(-1)
        end

        it 'should flash an success on success' do
          extension # make sure the object is created before the call
          expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:success, anything)
          delete_as instructor, :destroy, params: { course_id: course.id, id: extension.id }
        end

        it 'should flash an error on error' do
          expect_any_instance_of(ExtensionsController).to receive(:flash_now).with(:error, anything)
          allow_any_instance_of(Extension).to receive(:destroy).and_return(extension)
          delete_as instructor, :destroy, params: { course_id: course.id, id: extension.id }
        end
      end
    end
  end
end
