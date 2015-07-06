# extract all geometric relations between each pair
# of rects in each image (binomal[n,2] for each image)
require 'set'
require 'fileutils'
require_relative 'record'
require_relative 'transform.rb'

lcdat = ARGV[0]
listfn = ARGV[1]
File.open(listfn,'w') do |f|
	Record::seperate_records("",IO.foreach(lcdat),Record::parsers[:origin]).select{|r|r.rects!=nil}.each do |r|
		len = r.rects.length
		(0...(len-1)).each do |i|
			((i+1)...(len)).each do |j|
				if r.rects[j].type>r.rects[i].type
					temp = LCTransform.extract r.rects[i],r.rects[j]
				else
					temp = LCTransform.extract r.rects[j],r.rects[i]
				end
				f.puts temp.to_tsv_s
			end
		end
	end
end

