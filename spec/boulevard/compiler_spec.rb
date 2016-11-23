require 'fileutils'

describe Boulevard::Compiler do
  around(&temporary_directory)

  it 'returns you the code of a file' do
    file_a = file_name 'a.rb', 'puts "hello"'

    output = subject.(file_a)

    expect(output).to have_code 'puts "hello"'
  end

  it 'concats the code from mutiple files' do
    file_a = file_name 'a.rb', 'puts "a"'
    file_b = file_name 'b.rb', 'puts "b"'

    output = subject.(file_a, file_b)

    expect(output).to have_code %q[
      puts "a"
      puts "b"
    ]
  end

  it 'can take strings as code and files' do
    file_a = file_name 'a.rb', 'puts "a"'
    code_b = code 'puts "b"'
    file_c = file_name 'b.rb', 'puts "c"'

    output = subject.(file_a, code_b, file_c)

    expect(output).to have_code %q[
      puts "a"
      puts "b"
      puts "c"
    ]
  end

  it 'replaces `require_relative` calls with the code' do
    file_a = file_name 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file_name 'b.rb', %q[
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to have_code %q[
      puts "im file b"

      puts "im file a"
    ]
  end

  it 'works with double quotes' do
    file_a = file_name 'a.rb', %q[
      require_relative "b"
      puts "im file a"
    ]

    file_name 'b.rb', %q[
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to have_code %q[
      puts "im file b"

      puts "im file a"
    ]
  end

  it 'works recursively' do
    file_a = file_name 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file_name 'b.rb', %q[
      require_relative 'c'
      puts "im file b"
    ]

    file_name 'c.rb', %q[
      puts "im file c"
    ]

    output = subject.(file_a)

    expect(output).to have_code %q[
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
      file_a = file_name 'a.rb', %Q[
        #{require_line}
        puts "im file a"
      ]

      expect{ subject.(file_a) }.to raise_error described_class::RequireRelativeTooComplex
    end
  end

  it 'throws helpful error when it cannot find the required file' do
    file_a = file_name 'a.rb', %q[
      require_relative 'file-that-doesnt-exist'
      puts "im file a"
    ]

    expect { subject.(file_a) }.to raise_error Errno::ENOENT
  end

  it 'avoids infinite loops' do
    file_a = file_name 'a.rb', %q[
      require_relative 'b'
      puts "im file a"
    ]

    file_name 'b.rb', %q[
      require_relative 'a'
      puts "im file b"
    ]

    output = subject.(file_a)

    expect(output).to have_code %q[
      puts "im file b"
      puts "im file a"
    ]
  end
end
