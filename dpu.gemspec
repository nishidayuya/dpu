# frozen_string_literal: true

require_relative "lib/dpu/version"

Gem::Specification.new do |spec|
  spec.name = "dpu"
  spec.version = Dpu::VERSION
  spec.authors = ["Yuya.Nishida."]
  spec.email = ["yuya@j96.org"]

  spec.summary = "determine permanent URI"
  spec.homepage = "https://github.com/nishidayuya/dpu"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nishidayuya/dpu"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency("debug")
end
