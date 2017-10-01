require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end

  opts.on('-i', '--input FILENAME', 'input file') do |v|
    options[:input] = v
  end

  opts.on('-o', '--output FILENAME', 'output file') do |v|
    options[:output] = v
  end

  opts.on('-t', '--threshold th', Float, 'threshold') do |v|
    options[:threshold] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

p options
p ARGV
