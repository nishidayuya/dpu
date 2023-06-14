require "test_helper"

class DpuTest < Test::Unit::TestCase
  sub_test_case(".determine_permanent_uri") do
    data(
      git_scheme_uri: "git://github.com/foo_account_name/bar_repository_name.git",
      http_scheme_uri: "http://github.com/foo_account_name/bar_repository_name.git",
      https_scheme_uri: "https://github.com/foo_account_name/bar_repository_name.git",
      ssh_path: "git@github.com:foo_account_name/bar_repository_name.git",
      ssh_scheme_uri: "ssh://git@github.com/foo_account_name/bar_repository_name.git",
    )
    test("returns permanent URI") do |remote_url|
      create_repository(remote_url) do |repository_path|
        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/v1.0.0/file.txt"),
          Dpu.determine_permanent_uri(repository_path / "file.txt", nil, nil),
        )
      end
    end

    data(
      with_no_line_numbers: [nil, nil, nil],
      with_start_line_number: [1, nil, "L1"],
      with_both_line_numbers: [1, 2, "L1-L2"],
      with_same_line_numbers: [1, 1, "L1"],
    )
    test("returns with line number fragment") do |data|
      start_line_number, end_line_number, expected_fragment = *data
      remote_url = "git@github.com:foo_account_name/bar_repository_name.git"
      create_repository(remote_url) do |repository_path|
        result_uri = Dpu.determine_permanent_uri(
          repository_path / "file.txt",
          start_line_number,
          end_line_number,
        )
        assert_equal(expected_fragment, result_uri.fragment, "uri: #{result_uri}")
      end
    end

    test("returns commit id URI when no same content version") do
      remote_url = "git@github.com:foo_account_name/bar_repository_name.git"
      create_repository(remote_url) do |repository_path|
        file_path = repository_path / "file.txt"
        file_path.open("a") do |f|
          f.puts("additional text")
        end
        commit_all_files(repository_path)
        commit_id = fetch_commit_id(repository_path)

        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/#{commit_id}/file.txt"),
          Dpu.determine_permanent_uri(file_path, nil, nil),
        )
      end
    end

    test("returns same content version URI") do
      remote_url = "git@github.com:foo_account_name/bar_repository_name.git"
      create_repository(remote_url) do |repository_path|
        other_file_path = repository_path / "other_file_to_change_commit_id.txt"
        other_file_path.write("test\n")
        commit_all_files(repository_path)
        commit_id = fetch_commit_id(repository_path)

        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/v1.0.0/file.txt"),
          Dpu.determine_permanent_uri(repository_path / "file.txt", nil, nil),
        )
        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/#{commit_id}/other_file_to_change_commit_id.txt"),
          Dpu.determine_permanent_uri(other_file_path, nil, nil),
        )
      end
    end

    test("version tag pattern is '[0-9]*' and 'v[0-9]*'") do
      remote_url = "git@github.com:foo_account_name/bar_repository_name.git"
      create_repository(remote_url) do |repository_path|
        file_path = repository_path / "file.txt"
        file_path.open("a") do |f|
          f.puts("additional text")
        end
        commit_all_files(repository_path)
        tag("2.0.0", repository_path)

        other_file_path = repository_path / "other_file_to_change_commit_id.txt"
        other_file_path.write("test\n")
        commit_all_files(repository_path)
        tag("zz-test-1", repository_path)

        commit_id = fetch_commit_id(repository_path)

        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/2.0.0/file.txt"),
          Dpu.determine_permanent_uri(file_path, nil, nil),
        )
        assert_equal(
          URI("https://github.com/foo_account_name/bar_repository_name/blob/#{commit_id}/other_file_to_change_commit_id.txt"),
          Dpu.determine_permanent_uri(other_file_path, nil, nil),
        )
      end
    end
  end

  private

  def create_repository(remote_url)
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        File.write("file.txt", "A textfile\n")

        run_command("git init --quiet")
        run_command("git config user.email dpu_test@example.org")
        run_command("git config user.name dpu_test")
        commit_all_files
        tag("v1.0.0")
        run_command(*%W"git remote add origin", remote_url)
      end

      yield(Pathname(tmpdir))
    end
  end

  def commit_all_files(repository_path = Pathname(Dir.pwd))
    run_command("git add --all", chdir: repository_path)
    run_command("git commit --quiet --message commit", chdir: repository_path)
  end

  def tag(version, repository_path = Pathname(Dir.pwd))
    run_command(*%W"git tag #{version}", chdir: repository_path)
  end

  def fetch_commit_id(repository_path = Pathname(Dir.pwd))
    stdout = run_command_and_fetch_stdout("git rev-parse HEAD", chdir: repository_path)
    return stdout.chomp
  end

  def run_command(*args, **kwargs)
    system(*args, **kwargs, exception: true)
  end

  def run_command_and_fetch_stdout(*args, **kwargs)
    stdout, status = *Open3.capture2(*args, **kwargs)
    if !status.success?
      raise "failure to run command: args=#{args.inspect} kwargs=#{kwargs.inspect}"
    end
    return stdout
  end
end
