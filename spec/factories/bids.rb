# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bid do
    amount 1
    biddable_id 1
    biddable_type "MyString"
    user_id 1
    note "MyText"
  end
end
