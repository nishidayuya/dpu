class Dpu::ScmService::Github < Dpu::ScmService::Base
  REPOSITORY_URI_TEMPLATE = "https://github.com/%{account_name}/%{repository_name}"

  REMOTE_URL_PATTERN = [
    %r{\Agit://github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Ahttps?://github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Agit@github\.com:(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
    %r{\Assh://git@github\.com/(?<account_name>[^/]+)/(?<repository_name>[^/]+(?=\.git)|[^/]+)},
  ].then { |patterns|
    Regexp.union(*patterns)
  }

  REF_PREFIX = "blob"

  START_AND_END_LINE_NUMBER_FRAGMENT_TEMPLATE = "L%{start_line_number}-L%{end_line_number}"
end

Dpu::SCM_SERVICES << Dpu::ScmService::Github.new
