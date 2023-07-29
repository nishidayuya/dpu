class Dpu::ScmService::Base
  def determine_repository_uri(repository_http_or_ssh_url)
    md = self.class::REMOTE_URL_PATTERN.match(repository_http_or_ssh_url)
    return nil if !md

    url = self.class::REPOSITORY_URI_TEMPLATE % {
      account_name: md[:account_name],
      repository_name: md[:repository_name],
    }
    return URI(url)
  end

  def ref_prefix
    return self.class::REF_PREFIX
  end

  def determine_fragment(start_line_number, end_line_number)
    return nil if !start_line_number
    return "L#{start_line_number}" if !end_line_number || start_line_number == end_line_number
    return self.class::START_AND_END_LINE_NUMBER_FRAGMENT_TEMPLATE % {
      start_line_number: start_line_number,
      end_line_number: end_line_number,
    }
  end
end
