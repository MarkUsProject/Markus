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

  def self.validate_version!(version)
    return if version.match?(/\Av\d+\.\d+\.\d+\z/)

    warn "Error: version must match vX.Y.Z format, got '#{version}'"
    exit 1
  end
end
