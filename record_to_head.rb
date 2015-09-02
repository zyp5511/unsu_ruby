require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'
require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"

	opts.on("-s", "--source DIRNAME", "Image Directory") do |v|
		options[:source] = v
	end

	opts.on("-r", "--record FILENAME", "record file") do |v|
		options[:record] = v
	end

	opts.on("-n", "--node FILENAME", "head node list file") do |v|
		options[:node] = v
	end

	opts.on("--corenode [FILENAME]", "core head node list file") do |v|
		options[:corenode] = v
	end

	opts.on("-t", "--transform FILENAME", "transform file") do |v|
		options[:transform] = v
	end

	opts.on("-o", "--output FILENAME", "output file") do |v|
		options[:output] = v
	end

	opts.on("--bywords", "filtering group by number of visual words") do |v|
		options[:bywords] = true
	end

	opts.on("--complex", "filtering group by more complex logic") do |v|
		options[:complex] = true
	end

	opts.on("--group_threshold INTEGER",Integer, "assessing group by number of visual words") do |v|
		options[:group_threshold] = v
	end

	opts.on("--bias", "torso bias applied or not") do
		options[:bias] = true
	end

	opts.on("-h", "--help", "Prints this help") do
		puts opts
		exit
	end

end.parse!

src = options[:source]
lcdat = options[:record]
headdat = options[:node]
transfn = options[:transform]
exportfn= options[:output]

table = LCTransformTable.loadMap(transfn,1006) #hard coded cluster number, should be changed later
head = IO.readlines(headdat).map{|x|x.to_i}.to_set

if options.has_key?(:corenode)
	puts "core nodes defined"
	corehead = IO.readlines(options[:corenode]).map{|x|x.to_i}.to_set
end

lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:origin]).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{lcrecords.length} records"

if options.has_key?(:bias)
	puts "torso bias applied"
end

if options.has_key?(:group_threshold)
	puts "group threshold added"
	gpt = options[:group_threshold]
else
	puts "group threshold missing"
	exit
end

File.open(exportfn, 'w') do |f|
	lcrecords.each do |k,v|
		#group_set = v.groups.values.to_set.select{|y|y.rects.length>1}
		if options.has_key?(:complex)
			group_set = v.groups.values.to_set.select{|y|ns=y.rects.map{|x|x.type}.to_set;nsc = ns&corehead; ns.length>gpt||ns.length>gpt-1&&nsc.length>0;}
		elsif options.has_key?(:bywords)
			group_set = v.groups.values.to_set.select{|y|y.rects.map{|x|x.type}.to_set.length>gpt}
		else
			group_set = v.groups.values.to_set.select{|y|y.rects.length>gpt}
		end
		f.puts(k) if group_set.length>0
		group_set.each do |g|
			g.aggregate
			g.aggregated_rect.type = g.rects.map{|x|x.type}
			if options.has_key?(:bias)
				g.aggregated_rect.shift!(0,-0.5) #group bias
			end
			#f.puts g.aggregated_rect.to_short_s
			f.puts g.aggregated_rect.to_s
		end
	end
end

