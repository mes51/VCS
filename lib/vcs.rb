# coding: utf-8
$: << File.dirname(__FILE__)

require 'digest'
require 'fileutils'

require "vcs/diff_base.rb"
require "vcs/diff_creator.rb"
require "vcs/hunk.rb"
require "vcs/commit.rb"
require "vcs/index.rb"
require "vcs/repository.rb"
require "vcs/command.rb"
require "vcs/init_command.rb"
require "vcs/add_command.rb"
require "vcs/status_command.rb"
require "vcs/commit_command.rb"
