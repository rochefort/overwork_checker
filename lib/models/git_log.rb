# frozen_string_literal: true
class GitLog
  attr_accessor :project_name, :commit_at, :message, :day

  def initialize(project_name, commit_at, message)
    @project_name, @commit_at, @message = project_name, commit_at, message
    @day = basic_day
  end

  def tablize(project_name_max_length)
    project_name_fixed_size = "%-#{project_name_max_length}s" % @project_name
    [@day, @commit_at, project_name_fixed_size, @message].join(" | ")
  end

  private

    def basic_day
      if commit_at.hour < 6
        (commit_at - 1.day).to_date.to_s
      else
        commit_at.to_date.to_s
      end
    end
end
