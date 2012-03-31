$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")
require "vcs.rb"

sym = ARGV[0].to_sym

command = Object.constants.reject {
  |c| eval("!#{c}.kind_of?(Class) || #{c}.superclass != Command")
}.map { |c| Object.const_get(c) }.find { |c| c.command == sym }

if command
  args = ARGV.dup
  args.shift
  eval("#{command}").new(Dir.pwd).execute(args)
end
