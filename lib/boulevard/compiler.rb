module Boulevard
  class Compiler
    class RequireRelativeTooComplex < StandardError
    end

    def call(file_path, required_already = Set.new)
      return "" if required_already.include?(file_path)

      required_already << file_path

      contents = File.read(file_path)

      file_dir = File.dirname(file_path)

      contents.gsub(/^\s*require_relative.*$/) do |match|
        required_file_path = self.class.parse_require(match)
        resolved_file_path = File.expand_path(required_file_path, file_dir)
        resolved_file_path << '.rb'
        call(resolved_file_path, required_already)
      end
    end

    def self.parse_require(string)
      if match = string.match(/^\s*require_relative ["'](.*)["']\s*$/)
        match[1]
      else
        raise RequireRelativeTooComplex, "Couldn't parse the `require_relative`. Make it simpler."
      end
    end
  end
end
