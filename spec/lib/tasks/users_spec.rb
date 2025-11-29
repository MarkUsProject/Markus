require 'rails_helper'
require 'rake'

RSpec.describe 'db:prune_orphaned_end_users', type: :task do
  before do
    Rake.application.rake_require('tasks/users')
    Rake::Task.define_task(:environment)
    task.reenable
  end

  let(:task) { Rake::Task['db:prune_orphaned_end_users'] }

  def valid_end_user(user_name)
    EndUser.create!(
      user_name: user_name,
      first_name: 'First',
      last_name: 'Last',
      display_name: 'First Last'
    )
  end

  context 'when orphaned end users exist' do
    it 'deletes all orphaned end users and prints output' do
      user1 = valid_end_user('orphan1')
      user2 = valid_end_user('orphan2')

      relation = EndUser.where(id: [user1.id, user2.id])

      allow(EndUser).to receive(:get_orphaned_users).and_return(relation)

      expect do
        expect do
          task.invoke
        end.to output(/Found 2 orphaned EndUser records/).to_stdout
      end.to change { EndUser.count }.by(-2)
    end
  end

  context 'when no orphaned end users exist' do
    it 'prints the appropriate message and deletes nothing' do
      allow(EndUser).to receive(:get_orphaned_users).and_return(EndUser.none)

      expect do
        task.invoke
      end.to output(/No orphaned EndUser records found/).to_stdout

      expect(EndUser.count).to eq(0)
    end
  end
end
