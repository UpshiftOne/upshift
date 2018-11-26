# frozen_string_literal: true

FactoryBot.define do
  factory :contribution do
    project
    association :creator, factory: :user
    association :branch, factory: :vcs_branch
    title       { Faker::HarryPotter.quote }
    description { Faker::Lorem.paragraph }
  end
end
