FactoryBot.define do
  factory :key_pair do
    association :user, factory: :end_user
    public_key { 'ssh-rsa aaaaaa fake-key' }
  end
end
