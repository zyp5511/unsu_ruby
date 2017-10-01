require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'
require 'optparse'
require 'parallel'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: example.rb [options]'

  opts.on('-s', '--source DIRNAME', 'Image Directory') do |v|
    options[:source] = v
  end

  opts.on('-r', '--record FILENAME', 'record file') do |v|
    options[:record] = v
  end

  opts.on('-n', '--node FILENAME', 'head node list file') do |v|
    options[:node] = v
  end

  opts.on('--corenode [FILENAME]', 'core head node list file') do |v|
    options[:corenode] = v
  end

  opts.on('-t', '--transform FILENAME', 'transform file') do |v|
    options[:transform] = v
  end

  opts.on('--anchor-transform [FILENAME]', 'anchor transform file') do |v|
    options[:anchor] = v
  end

  opts.on('-o', '--output FILENAME', 'output file') do |v|
    options[:output] = v
  end

  opts.on('--gfilter FILTER', String, 'group filtering strategy') do |v|
    options[:gfilter] = v # options are: bywords, complex, strict
  end

  opts.on('--group_threshold INTEGER', Integer, 'assessing group by number of visual words') do |v|
    options[:group_threshold] = v
  end

  opts.on('--margin INTEGER', Integer, 'rect margins when grouping, 1=0.1*width or height') do |v|
    options[:margin] = v
  end

  opts.on('--bias', 'torso bias applied or not') do
    options[:bias] = true
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

src = options[:source]
lcdat = options[:record]
headdat = options[:node]
transfn = options[:transform]
exportfn = options[:output]

table = LCTransformTable.loadMap(transfn, 1006) # hard coded cluster number, should be changed later

if options.key?(:anchor)
  puts 'anchor table provided '
  anchor_table = LCTransformTable.loadMap(options[:anchor], 1006) # hard coded cluster number, should be changed later
else
  anchor_table = table
end
head = IO.readlines(headdat).map(&:to_i).to_set

if options.key?(:corenode)
  puts 'core nodes defined'
  corehead = IO.readlines(options[:corenode]).map(&:to_i).to_set
end

if options.key?(:margin)
  margin = options[:margin].to_f / 10
  puts "rect margin #{margin} specified"
else
  margin = 0
end

rec_list = Record.seperate_records(src, IO.foreach(lcdat), Record.parsers[:origin])
pred_list = Parallel.map(rec_list) do |r|
  [!r.rects.nil? &&
    begin
    r.pick_good_set head
    r.group_rects table, anchor_table, margin
    !r.groups.values.to_set.empty?
  end, r]
end.select { |criteria, _r| criteria }.map { |_c, r| r }

lcrecords = Hash[pred_list.map { |r| [r.filename, r] }]

puts "there are #{lcrecords.length} records"

puts 'torso bias applied' if options.key?(:bias)

if options.key?(:group_threshold)
  gpt = options[:group_threshold]
else
  puts 'group threshold missing'
  exit
end

File.open(exportfn, 'w') do |f|
  res = Parallel.map(lcrecords) do |k, v|
    # group_set = v.groups.values.to_set.select{|y|y.rects.length>1}
    if options.key?(:gfilter) # bywords > gpt or > gpt-1 while have a corenode in it.
      case options[:gfilter]
      when 'complex'
        group_set = v.groups.values.to_set.select do |y|
          ns = y.rects.map(&:type).to_set
          nsc = ns & corehead
          ns.length > gpt || ns.length > gpt - 1 && !nsc.empty?
        end
      when 'bywords'
        group_set = v.groups.values.to_set.select do |y|
          y.rects.map(&:type).to_set.length > gpt
        end
      when 'byrects'
        group_set = v.groups.values.to_set.select do |y|
          y.rects.length > gpt
        end
      else
        puts 'filter not found'
        exit
      end
    else # default, by number of rects in the group
      group_set = v.groups.values.to_set.select do |y|
        y.rects.length > gpt
      end
    end
    [k, group_set]
  end
  res.each do |k, group_set|
    f.puts(k) unless group_set.empty?
    group_set.each do |g|
      g.aggregate
      g.aggregated_rect.type = g.rects.map(&:type)
      if options.key?(:bias)
        g.aggregated_rect.shift!(0, -0.5) # group bias
      end
      # f.puts g.aggregated_rect.to_short_s
      f.puts g.aggregated_rect.to_s
    end
  end
end
