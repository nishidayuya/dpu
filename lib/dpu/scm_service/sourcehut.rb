class Dpu::ScmService::Sourcehut < Dpu::ScmService::Base
  REPOSITORY_URI_TEMPLATE = "https://git.sr.ht/~%{account_name}/%{repository_name}"

  REMOTE_URL_PATTERN = [
    %r{\Ahttps://git\.sr\.ht/\~(?<account_name>[^/]+)/(?<repository_name>.+)},
    %r{\Agit@git\.sr\.ht:\~(?<account_name>[^/]+)/(?<repository_name>.+)},
  ].then { |patterns|
    Regexp.union(*patterns)
  }

  REF_PREFIX = "tree"

  START_AND_END_LINE_NUMBER_FRAGMENT_TEMPLATE = "L%{start_line_number}-%{end_line_number}"
end

Dpu::SCM_SERVICES << Dpu::ScmService::Sourcehut.new
