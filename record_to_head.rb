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

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}]
	end
end

lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat)).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{lcrecords.length} records"

File.open(exportfn, 'w') do |f|
	lcrecords.each do |k,v|
		group_set = v.groups.values.to_set.select{|y|y.rects.length>1}
		f.puts(k) if group_set.length>0
		group_set.each do |g|
			g.aggregate
			f.puts g.aggregated_rect.to_short_s
		end
	end
end

