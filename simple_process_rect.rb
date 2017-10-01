require_relative 'record'
require_relative 'network'
require_relative 'voro_table'
require 'set'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: simple_process_rect.rb [options]'
  opts.on('-s', '--source DIRNAME', 'Image Directory') do |v|
    options[:source] = v
  end

  opts.on('-d', '--dest DIRNAME', 'Destination Image Directory') do |v|
    options[:dest] = v
  end

  opts.on('-r', '--record FILENAME', 'scan record file') do |v|
    options[:record] = v
  end

  opts.on('-o', '--operation OPER', 'output file') do |v|
    options[:operation] = v
  end

  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end

  opts.on('-t', '--threshold [VALUE]', Float, 'transform file') do |v|
    options[:threshold] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

oper = options[:operation]
src = options[:source]
des = options[:dest]
report = options[:record]

FileUtils.mkdir(des) unless File.directory?(des)

records = Record.seperate_records(src, IO.foreach(report), Record.parsers[:cv])
puts "there are #{records.length} records"

if oper == 'list'
  process = lambda do |x|
    puts x.filename
  end
elsif oper == 'draw'
  process = lambda do |x|
    if options.key?(:threshold)
      tt = options[:threshold]
      good_rects = x.rects.select { |r| r.dis > tt }
    else
      good_rects = x.rects
    end
    good_rects.each do |r|
      begin
        x.draw_rect(r, "\#ffffff")
      rescue Exception => e
        puts 'process_rect=======================Error!====================='
        puts x.inspect
        puts e
        puts e.backtrace.join("\n")
        puts 'process_rect=======================Error!====================='
      end
    end
    x.export des
  end
end

c = 0
records.each do |x|
  begin
    unless x.rects.empty?
      c += 1
      process.call(x)
    end
  rescue Exception => e
    puts 'process_rect=======================Error!====================='
    puts e.backtrace.join("\n")
    puts 'process_rect=======================Error!====================='
  end
end

puts " #{c} images processed"
