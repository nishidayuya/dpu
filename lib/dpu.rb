require "open3"
require "pathname"
require "uri"

require "version_sorter"

module Dpu
  autoload :Cli, "dpu/cli"
  autoload :VERSION, "dpu/vesion"

  SCM_SERVICES = []

  class << self
    def determine_permanent_uri(path_or_link, start_line_number = nil, end_line_number = nil)
      path = path_or_link.realpath
      relative_path = determine_relative_path(path)

      remote_url = get_remote_url(path)
      scm_service, repository_uri = determine_scm_service_and_repository_uri(remote_url)

      permanent_uri_parts = [
        repository_uri,
        scm_service.ref_prefix,
        find_same_content_version(path, relative_path) || determine_commit_id(path),
        relative_path,
      ]
      permanent_uri = URI(permanent_uri_parts.join("/"))
      permanent_uri.fragment = scm_service.determine_fragment(start_line_number, end_line_number)
      return permanent_uri
    end

    private

    def run_command(*args, **kwargs)
      stdout, status = *Open3.capture2(*args, **kwargs)
      if !status.success?
        raise "failure to run command: args=#{args.inspect} kwargs=#{kwargs.inspect}"
      end
      return stdout
    end

    def determine_relative_path(path)
      stdout = run_command("git rev-parse --show-toplevel", chdir: path.dirname)
      repository_top_path = Pathname(stdout.chomp)
      relative_path = path.relative_path_from(repository_top_path)
      return relative_path
    end

    def get_remote_url(path)
      return run_command("git remote get-url origin", chdir: path.dirname).chomp
    end

    def determine_scm_service_and_repository_uri(repository_http_or_ssh_url)
      SCM_SERVICES.each do |scm_service|
        repository_uri = scm_service.determine_repository_uri(repository_http_or_ssh_url)
        return scm_service, repository_uri if repository_uri
      end

      raise "unknown SCM service: #{repository_http_or_ssh_url}"
    end

    def determine_commit_id(path)
      stdout = run_command("git rev-parse HEAD", chdir: path.dirname)
      commit_id = stdout.chomp
      return commit_id
    end

    def find_same_content_version(path, relative_path_from_repository_root)
      stdout = run_command(*%w[git tag --list [0-9]* v[0-9]*], chdir: path.dirname)
      versions = VersionSorter.sort(stdout.each_line(chomp: true).select(&:ascii_only?))

      content_in_head = path.read
      same_content_version = versions.reverse_each.find { |version|
        content_in_version, _stderr, _status = *Open3.capture3(
          *%W[git show #{version}:#{relative_path_from_repository_root}],
          chdir: path.dirname,
        )
        content_in_head == content_in_version
      }
      return same_content_version
    end
  end
end

require "dpu/scm_service"
require "dpu/scm_service/github"
require "dpu/scm_service/sourcehut"
