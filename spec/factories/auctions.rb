# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :auction do
    title "MyString"
    description "MyText"
    user_id 1
    starting_bid 1
    auto_win 1
    bid_step 1
    winning_bid_id 1
    deadline "2013-04-23 02:32:25"
    status "MyString"
    featured 1
  end
end
