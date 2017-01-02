require 'set'

module Boulevard
  class Compiler
    class RequireRelativeTooComplex < StandardError
    end

    class FileName < Struct.new(:path)
      def id
        path
      end

      def contents
        File.read(path)
      end

      def dir
        File.dirname(path)
      end
    end

    class Code < Struct.new(:code)
      def id
        object_id
      end

      def contents
        code
      end

      def dir
        "."
      end
    end

    class Environment < Struct.new(:value)
      def id
        object_id
      end

      def contents
        "
        ;boulevard_environment = Marshal.load(#{Marshal.dump(value).inspect});
        "
      end

      def dir
        "."
      end
    end

    def call(*filenames_and_code)
      filenames_and_code.flatten
        .map { |compilable| compile(compilable) }
        .join("\n")
    end

    def compile(compilable, required_already = Set.new)
      return "" if required_already.include?(compilable.id)

      required_already << compilable.id

      compilable.contents.gsub(/^\s*require_relative.*$/) do |match|
        required_file_path = self.class.parse_require(match)
        resolved_file_path = File.expand_path(required_file_path, compilable.dir)
        resolved_file_path << '.rb'
        compile(FileName.new(resolved_file_path), required_already)
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
