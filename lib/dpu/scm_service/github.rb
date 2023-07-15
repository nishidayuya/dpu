class Dpu::ScmService::Github
  REPOSITORY_URI_TEMPLATE = "https://github.com/%{account_name}/%{repository_name}"

  REMOTE_URL_PATTERN = [
    %r{\Agit://github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Ahttps?://github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Agit@github\.com:(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Assh://git@github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
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
    return "blob"
  end

  def determine_fragment(start_line_number, end_line_number)
    return nil if !start_line_number
    return "L#{start_line_number}" if !end_line_number || start_line_number == end_line_number
    return "L#{start_line_number}-L#{end_line_number}"
  end
end

Dpu::SCM_SERVICES << Dpu::ScmService::Github.new
