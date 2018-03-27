# frozen_string_literal: true

FactoryGirl.define do
  factory :notification do
    association :target, factory: :account
    association :notifier, factory: :user
    association :notifiable, factory: :revision
    key 'revision.default'
  end
end
