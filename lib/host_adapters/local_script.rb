code_package = ARGV[0] or raise("First argument should be the code package")

Boulevard::Host.run code_package
