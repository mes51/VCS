# -*- coding: utf-8 -*-
$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")

RSpec.configure do |conf|
  conf.mock_with :rr
end

require "rspec"
require "fakefs"
require "vcs.rb"
