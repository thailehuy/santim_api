# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :hunt do
    title "MyString"
    description "MyText"
    user_id 1
    reward "MyText"
    winning_bid_id 1
    deadline "2013-04-23 02:31:25"
    status "MyString"
    featured 1
  end
end
