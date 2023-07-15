class Dpu::ScmService::Sourcehut
  REPOSITORY_URI_TEMPLATE = "https://git.sr.ht/~%{account_name}/%{repository_name}"

  REMOTE_URL_PATTERN = [
    %r{\Ahttps://git\.sr\.ht/\~(?<account_name>[^/]+)/(?<repository_name>.+)},
    %r{\Agit@git\.sr\.ht:\~(?<account_name>[^/]+)/(?<repository_name>.+)},
  ].then { |patterns|
    Regexp.union(*patterns)
  }

  def determine_repository_uri(repository_http_or_ssh_url)
    md = REMOTE_URL_PATTERN.match(repository_http_or_ssh_url)
    return nil if !md

    url = REPOSITORY_URI_TEMPLATE % {
      account_name: md[:account_name],
      repository_name: md[:repository_name],
    }
    return URI(url)
  end

  def ref_prefix
    return "tree"
  end

  def determine_fragment(start_line_number, end_line_number)
    return nil if !start_line_number
    return "L#{start_line_number}" if !end_line_number || start_line_number == end_line_number
    return "L#{start_line_number}-#{end_line_number}"
  end
end

Dpu::SCM_SERVICES << Dpu::ScmService::Sourcehut.new
