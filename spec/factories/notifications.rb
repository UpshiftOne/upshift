# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :target, factory: :account
    association :notifier, factory: :user
    key { 'notification.default' }
  end
end
