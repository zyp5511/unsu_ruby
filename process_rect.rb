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

if type == "if"
	clufn= ARGV[5]
	head = IO.readlines(clufn).map{|x|x.to_i}.to_set
	c = 0;
	cp = 0;
	begin
		transfn = ARGV[6]
		table = LCTransformTable.loadMap(transfn,400) #hard coded cluster number, should be changed later
	rescue Exception => e
		puts e
	end

	begin
		netfn = ARGV[7]
		nettable = Network.loadTable(netfn) 

		elfn = ARGV[8]
		nettable.restrict elfn
	rescue Exception => e
		puts e
	end

	begin
		global_fn = ARGV[9]
		global_table=Point.loadGlobal(global_fn)
	rescue Exception => e
		puts e
	end

	begin
		vorofn = ARGV[10]
		vorotable = VoroTable.loadTable(vorofn) 
	rescue Exception => e
		puts e
	end
	#puts global_table
	#define lambda expression
	if oper == "list"
		process = ->(x){
			puts x.filename;
		}
	elsif oper == "draw"
		process = ->(x){
			x.headset.each{|r|x.draw_rect r}
			x.export
		}
	elsif oper == "crop"
		process = ->(x){
			x.headset.each{|r|x.crop_rect r}
		}
	elsif oper == "draw_inferred"
		process = ->(x){
			x.headset.each{|r|x.draw_rect (table.transform r)}
			x.export
		}
	elsif oper == "crop_inferred"
		process = ->(x){
			x.headset.each{|r|x.crop_rect (table.transform r)}
		}
	elsif oper == "crop_group_med_inferred"
		process = ->(x){
			x.group_rects table
			if x.groups.values.to_set.length > 0
				x.groups.values.to_set.each_with_index do |g,i|
					cp+=1
					x.crop_rect(g.aggregate)
				end
			end
		}
	elsif oper == "draw_group_med_inferred"
		process = ->(x){
			x.group_rects table
			if x.groups.values.to_set.length > 1
				x.groups.values.to_set.each_with_index do |g,i|
					g.inferred_rects.each{|r|x.draw_rect((r), x.colortab[i*10])}
					x.draw_rect(g.aggregate,"\#ffffff")
				end
				x.export
			end
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
						#g.aggregate_with_table nettable
						g.calibrate_global global_table
					rescue Exception => e
						puts e
						puts e.backtrace
						puts
					end
				end
				changed = x.prune_group 
				x.bettergroups.each_with_index do |g,i|
					gqual = vorotable.group_quality g
					x.draw_group(g,x.colortab[(i+1)*31],"#{gqual}")
					#x.draw_group(g,x.colortab[(i+1)*31],"x")
					puts "#{x.filename}\t#{i}\t#{gqual}"
				end
				#if changed
				x.export
				#end
			end
		}
	elsif oper == "draw_group_net"  # old name is draw_group
		process = ->(x){
			x.group_rects_with_graph  nettable
			goodgroups=x.groups.values.to_set
			if goodgroups.length > 0
				goodgroups.each_with_index do |g,i|
					if g.rects.length>2
						g.rects.each{|r|x.draw_rect((r), x.colortab[(i+1)*31])}
					end
				end
				x.export
				x.export_dot
			end
		}
	elsif oper == "draw_group_net_inferred"
		process = ->(x){
			x.group_rects_with_graph  nettable,table
			goodgroups=x.groups.values.to_set.select{|y|y.rects.length>3}
			if goodgroups.length > 0
				goodgroups.each_with_index do |g,i|
					g.rects.each{|r|x.draw_rect((r), x.colortab[(i+1)*11],true)}
					x.draw_rect(g.aggregate,"\#ffffff",true)
					g.aggregate_with_table nettable
					g.rects.each{|r|x.draw_rect((r), x.colortab[(i+1)*31])}
					g.reset_infer table
					x.draw_rect(g.aggregate,"\#ffffff")
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
			puts $!
			puts caller[0..100]
			puts "process_rect=======================Error!====================="
		end
	end
	puts " #{c} images processed"
	puts " #{cp} patches created"
else
	records.each do|x|
		puts "there are #{x.rects.length} rects"
		x.rects.each{|r|x.crop_rect r}
	end
end
