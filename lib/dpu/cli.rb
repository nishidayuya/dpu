class Dpu::Cli
  USAGE = <<~EOS
    #{File.basename(Process.argv0)} path start_line_number end_line_number
  EOS

  class << self
    def run(argv)
      s_path, s_start_line_number, s_end_line_number = *argv
      if !s_path
        $stderr.puts(USAGE)
        exit(1)
      end

      path = Pathname(s_path).expand_path
      start_line_number = s_start_line_number&.to_i
      end_line_number = s_end_line_number&.to_i

      uri = Dpu.determine_permanent_uri(path, start_line_number, end_line_number)
      puts(uri)
    end
  end
end
