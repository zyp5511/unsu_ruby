# count how many rects detected in each image.
require 'set'
require 'fileutils'
require_relative 'record'

lcdat = ARGV[0]
Record::seperate_records("","",IO.foreach(lcdat)).each{|r|puts "#{r.filename}:#{r.rects.length}"}

