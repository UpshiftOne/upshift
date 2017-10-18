# frozen_string_literal: true

module Discussions
  #  Suggestions in projects
  class Suggestion < Base
    # Associations
    belongs_to :project, class_name: 'Project', counter_cache: true

    # Validations
    validates :type, inclusion: { in: %w[Discussions::Suggestion] }
  end
end
