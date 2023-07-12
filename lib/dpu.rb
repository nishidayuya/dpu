require "open3"
require "pathname"
require "uri"
require "version_sorter"

module Dpu
  autoload :Cli, "dpu/cli"
  autoload :VERSION, "dpu/vesion"

  class << self
    GITHUB_REPOSITORY_URI_TEMPLATE = "https://github.com/%{account_name}/%{repository_name}"
    REMOTE_URL_PATTERN = [
      %r{\Agit://github\.com/(?<account_name>[^/]+)/(?<repository_name>.+)(?=\.git)},
      %r{\Ahttps?://github\.com/(?<account_name>[^/]+)/(?<repository_name>.+)(?=\.git)},
      %r{\Agit@github\.com:(?<account_name>[^/]+)/(?<repository_name>.+)(?=\.git)},
      %r{\Assh://git@github\.com/(?<account_name>[^/]+)/(?<repository_name>.+)(?=\.git)},
    ].then { |patterns|
      Regexp.union(*patterns)
    }

    def determine_permanent_uri(path_or_link, start_line_number = nil, end_line_number = nil)
      path = path_or_link.realpath
      relative_path = determine_relative_path(path)

      version = find_same_content_version(path, relative_path)
      ref = version&.ascii_only? ? version : determine_commit_id(path)

      permanent_uri_parts = [
        determine_repository_uri(path),
        "blob",
        ref,
        relative_path,
      ]
      permanent_uri = URI(permanent_uri_parts.join("/"))
      permanent_uri.fragment = determine_fragment(start_line_number, end_line_number)
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

    def determine_repository_uri(path)
      stdout = run_command("git remote get-url origin", chdir: path.dirname)
      repository_http_or_ssh_url = stdout.chomp

      md = REMOTE_URL_PATTERN.match(repository_http_or_ssh_url)
      if !md
        return URI(repository_http_or_ssh_url)
      end

      url = GITHUB_REPOSITORY_URI_TEMPLATE % {
        account_name: md[:account_name],
        repository_name: md[:repository_name],
      }
      return URI(url)
    end

    def determine_commit_id(path)
      stdout = run_command("git rev-parse HEAD", chdir: path.dirname)
      commit_id = stdout.chomp
      return commit_id
    end

    def find_same_content_version(path, relative_path_from_repository_root)
      stdout = run_command(*%w[git tag --list [0-9]* v[0-9]*], chdir: path.dirname)
      versions = VersionSorter.sort(stdout.each_line(chomp: true).to_a)

      content_in_head = path.read
      same_content_version = versions.reverse_each.find { |version|
        content_in_version, _status = *Open3.capture2(*%W[git show #{version}:#{relative_path_from_repository_root}], chdir: path.dirname, err: "/dev/null")
        content_in_head == content_in_version
      }
      return same_content_version
    end

    def determine_fragment(start_line_number, end_line_number)
      return nil if !start_line_number
      return "L#{start_line_number}" if !end_line_number || start_line_number == end_line_number
      return "L#{start_line_number}-L#{end_line_number}"
    end
  end
end
