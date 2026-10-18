# frozen_string_literal: true

require 'open3'

# Shared helper methods for release scripts.
module ReleaseHelpers
  REPO = 'MarkUsProject/Markus'

  class CommandError < RuntimeError; end

  def self.run(*cmd)
    stdout, stderr, status = Open3.capture3(*cmd)
    return stdout if status.success?

    raise CommandError, "Command failed: #{cmd.inspect}\n#{stderr}".strip
  end

  def self.run_stripped(*cmd)
    run(*cmd).strip
  end

  def self.command_succeeds?(*cmd)
    _, _, status = Open3.capture3(*cmd)
    status.success?
  end

  # Files changed by a PR's merge or squash commit, from local git (no 300-file limit).
  def self.pr_files(sha)
    run_stripped('git', 'diff', '--name-only', "#{sha}^1", sha).split("\n")
  end

  # Unified diff of a PR's merge or squash commit, from local git, optionally limited to +paths+.
  def self.pr_diff(sha, *paths)
    cmd = ['git', 'diff', "#{sha}^1", sha]
    cmd += ['--', *paths] unless paths.empty?
    run(*cmd)
  end

  # The +/- lines of a unified diff, without the +++/--- file headers.
  def self.change_lines(diff_text)
    diff_text.lines.select { |l| l.start_with?('+', '-') && !l.start_with?('+++', '---') }
  end

  # A lockfile version line: indentation + key, then a version (Gemfile.lock and package*.json).
  VERSION_LINE = /\A(\s*)"?([^"(:]+?)"?\s*[:(]\s*"?[\^~><=\s]*([0-9][^",)\s]*)/

  # Files the sysadmins act on at deploy, by category (File.fnmatch patterns, repo-relative).
  # Ruby and Node versions are pinned only in .dockerfiles/Dockerfile.
  CHANGE_CATEGORIES = {
    'gems' => ['Gemfile', 'Gemfile.lock'],
    'js' => ['package.json', 'package-lock.json'],
    'python' => ['requirements-*.txt'],
    'system' => ['markus.control', '.dockerfiles/Dockerfile'],
    'settings' => ['config/settings.yml', 'config/settings/*.yml', 'config/application.rb']
  }.freeze

  # The CHANGE_CATEGORIES key that +path+ falls under, or nil.
  def self.change_category(path)
    CHANGE_CATEGORIES.find { |_, globs| globs.any? { |g| File.fnmatch?(g, path, File::FNM_PATHNAME) } }&.first
  end

  # PR numbers cited in +text+ as `(#N)`, `(#N/#M)` or `(#N, #M)`, the forms the
  # validators' pr_numbers reads.
  def self.pr_refs(text)
    text.scan(%r{\(#\d+(?:[/,] *#\d+)*\)}).flat_map { |ref| ref.scan(/\d+/) }.map(&:to_i)
  end

  def self.commit_exists?(sha)
    !sha.to_s.empty? && command_succeeds?('git', 'cat-file', '-e', "#{sha}^{commit}")
  end

  def self.validate_version!(version)
    return if version.match?(/\Av\d+\.\d+\.\d+\z/)

    warn "Error: version must match vX.Y.Z format, got '#{version}'"
    exit 1
  end
end
