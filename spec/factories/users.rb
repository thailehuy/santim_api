# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name "MyString"
    last_name "MyString"
    email "MyString"
    hashed_password "MyString"
    last_seen_at "2013-04-17 16:34:34"
    admin false
  end
end
