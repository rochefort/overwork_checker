#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage: bundel exec ruby lib/overwork_checker.rb $your_projects_path

require "pp"
require "time"

require "active_support"
require "active_support/core_ext"
require "parallel"

require_relative "./models/git_log"

class OverWorkChecker
  def initialize(projects_path)
    @projects_path = projects_path
    @logs = nil
  end

  def print
    project_name_max_length = logs.map(&:project_name).map(&:length).max
    logs.each { |log| puts log.tablize(project_name_max_length) }
  end

  def print_by_month
    result = Hash.new(0)
    logs.each do |log|
      match_data = log.day.match(/\d{4}-\d{2}/)
      result[match_data[0]] += 1 if match_data
    end
    pp result
  end

  private

    def logs
      @logs ||= over_work_logs
    end

    def over_work_logs
      git_logs
        .find_all { |log| !office_hour?(log.commit_at.hour) }
        .group_by(&:day)
        .inject([]) { |result, (_day, log)| result << log.max_by(&:commit_at) }
    end

    def office_hour?(hour)
      hour >= 6 && hour <= 18
    end

    def git_logs
      logs = []
      lookup_projects do |dir|
        git_logs = `git log --date=local --pretty="%cd,%s"`
        git_logs.each_line do |log|
          commit_at, message = log.chomp.split(",")
          commit_at = Time.parse(commit_at)
          logs << GitLog.new(dir, commit_at, message)
        end
      end
      logs.sort { |x, y| x.commit_at <=> y.commit_at }
    end

    def lookup_projects
      path = projects_path? ? "#{@projects_path}/*" : "#{@projects_path}"
      Dir.glob(path).each do |dir|
        Dir.chdir(dir) do
          yield(dir) if block_given?
        end
      end
    end

    # .git ディレクトリが存在する場合、projectsを複数まとめた
    # projects_path ではないと判断する。
    #
    # 以下のディレクトリ構成の場合、repos はprojects_pathと判断する。
    #
    # repos (has no .git)
    # ├── project1 (has .git)
    # └── project2 (has .git)
    def projects_path?
      status = false
      Dir.chdir(@projects_path) do
        status = !File.exist?(".git")
      end
      status
    end
end

if __FILE__ == $0
  abort "Invalid Argument: Specify your projects path." if ARGV.size < 1
  owc = OverWorkChecker.new(ARGV[0])
  owc.print
  puts
  owc.print_by_month
end
