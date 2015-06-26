require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'

src = ARGV[0]
lcdat = ARGV[1]
headdat = ARGV[2]
transfn = ARGV[3]
exportfn= ARGV[4]

table = LCTransformTable.loadMap(transfn,1006) #hard coded cluster number, should be changed later
head = IO.readlines(headdat).map{|x|x.to_i}.to_set

lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:origin]).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{lcrecords.length} records"

File.open(exportfn, 'w') do |f|
	lcrecords.each do |k,v|
		group_set = v.groups.values.to_set.select{|y|y.rects.length>1}
		f.puts(k) if group_set.length>0
		group_set.each do |g|
			g.aggregate
			g.aggregated_rect.shift!(0,-0.5)
			#f.puts g.aggregated_rect.to_short_s
			f.puts g.aggregated_rect.to_s
		end
	end
end

