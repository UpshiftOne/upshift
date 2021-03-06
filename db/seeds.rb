# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).

require 'faker'
require 'factory_bot_rails'

# Clear the contents of the file storage
FileUtils.rm_rf Dir.glob(Rails.root.join(Settings.file_storage, '*'))

# Create three users
%w[alice bob carla].each do |handle|
  account = Account.new(email: "#{handle}@#{Settings.app_domain}",
                        password: 'password')
  account.build_user name: handle.capitalize, handle: handle
  account.save
  account.reload # reload account to ensure that they were persisted
end

# Create three projects per user
Profiles::User.find_each do |user|
  3.times do |i|
    FactoryBot.create :project, owner: user, slug: "project-#{i + 1}"
  end
end
