require 'fileutils'

describe Boulevard::Compiler do
  around do |block|
    Dir.mktmpdir do |dir|
      @dir = dir
      block.call
    end
  end

  def file(name, contents)
    File.join(@dir, name).tap do |path|
      FileUtils.mkdir_p File.dirname(path)
      File.write path, file_content(contents)
    end
  end

  def file_content(string)
    string.each_line.map(&:strip).join("\n")
  end

  it 'returns you the code of a file' do
    file_a = file 'a.rb', 'puts "hello"'

    output = subject.(file_a)

    expect(output).to eq 'puts "hello"'
  end

  it 'replaces `require_relative` calls with the code' do
    file_a = file 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file 'b.rb', %q[
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to eq file_content %q[
      puts "im file b"

      puts "im file a"
    ]
  end

  it 'works with double quotes' do
    file_a = file 'a.rb', %q[
      require_relative "b"
      puts "im file a"
    ]

    file 'b.rb', %q[
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to eq file_content %q[
      puts "im file b"

      puts "im file a"
    ]
  end


  it 'works recursively' do
    file_a = file 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file 'b.rb', %q[
      require_relative 'c'
      puts "im file b"
    ]

    file 'c.rb', %q[
      puts "im file c"
    ]

    output = subject.(file_a)

    expect(output).to eq file_content %q[
      puts "im file c"

      puts "im file b"

      puts "im file a"
    ]
  end


  it 'errors if it finds `require_relative` that it cannot parse' do
    [
      "require_relative some_var",
      "require_relative %q[some other thing]",
      "require_relative \\\n'b'",
    ].each do |require_line|
      file_a = file 'a.rb', %Q[
        #{require_line}
        puts "im file a"
      ]

      expect{ subject.(file_a) }.to raise_error described_class::RequireRelativeTooComplex
    end
  end

  it 'throws helpful error when it cannot find the required file' do
    file_a = file 'a.rb', %q[
      require_relative 'file-that-doesnt-exist'
      puts "im file a"
    ]

    expect { subject.(file_a) }.to raise_error Errno::ENOENT
  end

  it 'avoids infinite loops' do
    file_a = file 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file 'b.rb', %q[
      require_relative 'a'
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to eq file_content %q[
      puts "im file b"

      puts "im file a"
    ]
  end
end
