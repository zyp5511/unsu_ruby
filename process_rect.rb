require_relative 'record'
require_relative 'network'
require_relative 'voro_table'
require 'set'

type = ARGV[0]
oper = ARGV[1]
src = ARGV[2]
des = ARGV[3]
report = ARGV[4]

records = Record::seperate_records(src,des,IO.foreach(report))
puts "there are #{records.length} records"

#head nodes, legacy
clufn= ARGV[5]
head = IO.readlines(clufn).map{|x|x.to_i}.to_set
c = 0;
# all pair stat table and selected network2 edges
begin
	netfn = ARGV[7]
	nettable = Network.loadTable(netfn) 
	elfn = ARGV[8]
	nettable.restrict elfn
rescue Exception => e
	puts e
end
# global position for each node
begin
	global_fn = ARGV[9]
	global_table=Point.loadGlobal(global_fn)
rescue Exception => e
	puts e
end
# voronoi table for group quality assessment
begin
	vorofn = ARGV[10]
	vorotable = VoroTable.loadTable(vorofn) 
rescue Exception => e
	puts e
end

if oper == "list"
	process = ->(x){
		puts x.filename;
	}
elsif oper == "draw_group_net_global"
	process = ->(x){
		x.group_rects_with_graph  nettable
		goodgroups=x.groups.values.to_set
		if goodgroups.length > 0
			goodgroups.each_with_index do |g,i|
				if g.rects.map{|x|x.type}.to_set.length>2
					begin
						g.calibrate_global global_table
						x.draw_rect(g.infer_part_globally(global_table,100),"\#ffffff")
						x.draw_rect(g.infer_part_globally(global_table,482),"\#ffff00")
					rescue Exception => e
						puts e
					end
				end
			end
			x.export
		end
	}
elsif oper == "draw_group_quality"
	process = ->(x){
		x.group_rects_with_graph  nettable
		goodgroups=x.groups.values.to_set
		bettergroups = goodgroups.select{|g|g.rects.map{|x|x.type}.to_set.length>2}
		if !bettergroups.empty?
			changed = false;
			bettergroups.each_with_index do |g,i|
				begin
					#g.aggregate_with_table nettable # tweaking position according to neighbors' position
					g.calibrate_global global_table
				rescue Exception => e
					puts e
					puts e.backtrace
					puts
				end
			end
			#changed = x.prune_group #grouping merging
			#x.bettergroups.each_with_index do |g,i|
			bettergroups.each_with_index do |g,i|
				gqual = vorotable.group_quality g
				x.draw_group(g,x.colortab[(i+1)*31],"#{gqual}")
				puts "#{x.filename}\t#{i}\t#{gqual}"
			end
			x.export
		end
	}
elsif oper == "draw_group_car"
	process = ->(x){
		x.prune_rect 50
		x.group_rects_with_graph  nettable
		goodgroups=x.groups.values.to_set
		bettergroups = goodgroups.select{|g|g.rects.map{|x|x.type}.to_set.length>2}
		if !bettergroups.empty?
			changed = false;
			bettergroups.each_with_index do |g,i|
				begin
					#g.aggregate_with_table nettable # tweaking position according to neighbors' position
					g.calibrate_global global_table
				rescue Exception => e
					puts e
					puts e.backtrace
					puts
				end
			end
			bettergroups.each_with_index do |g,i|
				gqual = vorotable.group_quality g
				x.draw_group(g,x.colortab[(i+1)*31],"#{gqual}")
				puts "#{x.filename}\t#{i}\t#{gqual}"
			end
			x.export
		end
	}
end

records.each do|x|
	begin
		x.pick_good_set head
		if !x.headset.empty?
			c+=1
			process.call(x)
		end
	rescue Exception => e
		puts "process_rect=======================Error!====================="
		puts e.backtrace.join("\n")
		puts "process_rect=======================Error!====================="
	end
end
puts " #{c} images processed"
