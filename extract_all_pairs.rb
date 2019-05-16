# extract all geometric relations between each pair
# of rects in each image (binomal[n,2] for each image)
require 'set'
require 'fileutils'
require_relative 'record'
require_relative 'transform.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-i', '--input FILENAME', 'input file') do |v|
    options[:input] = v
  end

  opts.on('-o', '--output FILENAME', 'output file') do |v|
    options[:output] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

lcdat = options[:input]
listfn = options[:output]

File.open(listfn, 'w') do |f|
  Record.seperate_records('', IO.foreach(lcdat), Record.parsers[:origin]).reject { |r| r.rects.nil? }.each do |r|
    len = r.rects.length
    (0...(len - 1)).each do |i|
      ((i + 1)...len).each do |j|
        temp = if r.rects[j].type > r.rects[i].type  #here we want to make sure the edge is directed from small cluster number to big cluster number
                 LCTransform.extract r.rects[i], r.rects[j]
               else
                 LCTransform.extract r.rects[j], r.rects[i]
               end
        f.puts temp.to_tsv_s
      end
    end
  end
end
