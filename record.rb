require 'rmagick'
require 'fileutils'
require 'set'

require 'rgl/adjacency'
require 'rgl/traversal'
require 'rgl/dot'
require 'rgl/connected_components'
#require 'rgl/edge_properties_map'

require_relative 'rect_group'
require_relative 'transform'

class Record
	attr_accessor :rects,:filename
	attr_accessor :inferred_rects
	attr_accessor :groups
	attr_accessor :bettergroups
	attr_accessor :graph
	attr_accessor :edges
	@@colors = Hash.new{|h,k|h[k]="\##{Random.rand(16777216).to_i.to_s(16).rjust(6,'0')}"}
	def initialize(filename,src,rects)
		@filename = filename
		@src = src
		@rects = rects
	end

	def colortab
		@@colors
	end

	def pick_good_set head
		if !@rects.nil?
			@rects.select!{|r|head.include? r.type }
		end
	end

	## reject rects of type which appears too many times.
	def prune_rect threshold
		puts "before pruning:#{@rects.length}"
		rejset = @rects.group_by(&:type).map{|x,y|[x,y.length]}.reject{|p|p[1]<threshold}.map{|p|p[0]}.to_set
		@rects.reject!{|r|rejset.include?(r.type)}
		puts "after pruning:#{@rects.length}"
	end

	## pruning group with <=2 rects and merge groups by origin position
	def prune_group
		groupscurrent = @groups.values.to_set.select{|g|g.rects.map{|x|x.type}.to_set.length>2}.to_a
		its = 0;
		changed = true;
		while(its<3&&changed) do
			gmerged = Hash.new(false)
			groupsnew = [];
			changed = false;

			gidx = (0...groupscurrent.length).to_a
			gidx.combination(2).each do |gs,gt|
				if !gmerged[gs] and !gmerged[gt] and groupscurrent[gs].compatible? groupscurrent[gt]
					gnew = RectGroup.merge(groupscurrent[gs],groupscurrent[gt])
					oldlen1=groupscurrent[gs].rects.length
					oldlen2=groupscurrent[gt].rects.length
					newlen=gnew.rects.length
					puts "#{@filename} Group merged #{oldlen1}+#{oldlen2}=#{newlen}"
					gmerged[gs]=true
					gmerged[gt]=true
					changed = true
					groupsnew<<gnew
				end
			end
			gidx.select{|g| !gmerged[g]}.each do |g|
				groupsnew<<groupscurrent[g]
			end
			groupscurrent = groupsnew
			its=its+1
		end
		@bettergroups = groupsnew 
		changed
	end


	def group_rects_with_graph(net)
		@groups = Hash.new
		if @rects==nil
			raise "Empty goodset"
		else
			head_node_lookup = Hash.new
			@graph = RGL::AdjacencyGraph.new
			#@edges = Hash.new()
			@rects.each_with_index do |r,i| 
				head_node_lookup[r]=i
				@graph.add_vertex(i*10000+r.type)
			end
			hidx = (0...@rects.size).to_a
			hidx.combination(2).each do |r,s|
				same = @rects[r].type == @rects[s].type
				if !same
					rule = net.query @rects[r].type, @rects[s].type
					if !rule.nil?
						rdis=((rule.transform_with_type @rects[r]).diff @rects[s])
					end
				else
					rdis = @rects[r].diff @rects[s]
				end
				if (same or !rule.nil?) and rdis < 0.8 # old value is 0.5
					@graph.add_edge(r*10000+@rects[r].type,
									s*10000+@rects[s].type)
					#@edges[[head_node_lookup[r]*10000+r.type, head_node_lookup[s]*10000+s.type]]=rdis;
				end
			end
			@graph.each_connected_component do |c|
				c.inject(RectGroup.new) do |rg,ri|
					@groups[@rects[ri/10000]]=rg;
					rg.add_rect @rects[ri/10000];
					rg
				end
			end
		end
	end


	def load_img
		@ori ||= Magick::Image.read(File.join(@src,@filename).to_s).first
	end

	def export dest
		self.load_img
		@ori.write(File.join(dest,@filename).to_s)
	end

	#def export_dot
	#	fb = File.basename(@filename,File.extname(@filename))
	#	fn = fb +"_el.dot"
	#	#@graph.write_to_graphic_file('png',File.join(@dest,fb+"_el"));
	#	data = @graph.to_dot_graph(map: RGL::EdgePropertiesMap.new(@edges,false))
	#	File.open(File.join(@dest,fn),"w")do |f|
	#		f.puts data
	#	end
	#end

	def draw_group g,color,title=nil
		begin
			g.rects.each{|r|draw_rect(r, color)}
			if title!=nil
				titlex = g.rects.map{|r|r.x}.inject(:+)/g.rects.length
				titley = g.rects.map{|r|r.y}.inject(:+)/g.rects.length
				rdraw = Magick::Draw.new
				rdraw.pointsize(24)
				rdraw.text(titlex,titley,title)
				rdraw.draw(@ori)
			end
		rescue Exception => e
			puts e.backtrace
			puts "g=#{g}"
		end

	end

	def draw_rect(rect,color=@@colors[rect.type],dash=false)
		self.load_img
		rdraw = Magick::Draw.new
		rdraw.text(rect.x,rect.y+10,rect.type.to_s) if !rect.type.nil?
		rdraw.stroke(color).stroke_width(0.5)
		if dash
			rdraw.stroke_dasharray(5,5)
		end
		rdraw.fill("transparent")
		rdraw.rectangle(rect.x,rect.y,rect.x+rect.w-1,rect.y+rect.h-1)
		rdraw.draw(@ori)
	end

	def crop_rect(rect,dest)
		self.load_img
		temp = @ori.crop(rect.x,rect.y,rect.w,rect.h,true)
		type = rect.type
		subdir = "#{dest}/#{type}".chomp
		if !File.directory?(subdir)
			FileUtils.mkdir(subdir)
		end
		temp.write("#{File.join(subdir,File.basename(@filename, File.extname(@filename))).to_s}_#{rect.x}+#{rect.y}+#{rect.w}x#{rect.h}_#{type}#{File.extname(@filename)}")
	end

	## different parsers for records of different format
	@@record_parsers={
		origin:
		lambda do |src,lines|
			filename = lines[0];
			vectors = lines[1]
			if lines.length > 2
				tmp = lines.drop(2).take_while{|x| x.include?(":")&&!x.include?("=>")}
				if !tmp.nil?
					rects = tmp.map do |l| 
						begin 
							Rect.makeRect(l) 
						rescue 
							puts lines.inspect
						end
					end
				end
			end
			Record.new(filename,src,rects)
		end,
		cv:
		lambda do |src, lines|
			filename = lines[0];
			rects = lines.drop(1).map{|x|Rect.makePureRect(x)}
			Record.new(filename,src,rects)
		end
	}

	def self.parsers
		@@record_parsers
	end

	def self.seperate_records(src,lines,record_parser)
		lines.map{|x|x.chomp}.chunk{|l|self.is_img? l}.each_slice(2).map do |a|
		 	# puts a[0][1].inspect if a[0][1].length>1;
			record_parser.call(src,a[1][1].unshift(a[0][1].last))
		end
	end

	def self.is_img? l
		l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") 
	end


	## deprecated method, kept to run old diff.rb script
	def group_rects  table,anchor_table,margin=0
		@groups = Hash.new
		@anchor_groups = Hash.new
		if @rects.nil?
			raise "Empty goodset"
		else
			@inferred_rects = Hash.new
			@rects.each do |r| 
				ir = table.transform r
				air = anchor_table.transform r
				@inferred_rects[r]=ir;
				if !@anchor_groups.values.empty?
					rr, g = @anchor_groups.find{|k,v|v.include(air,margin)}
				else 
					g = nil
				end
				if !g.nil?
					@anchor_groups[r]=g
					@groups[r]=@groups[rr]
					g.add air
					@groups[rr].add ir
				else
					@groups[r]=RectGroup.new(ir)
					@anchor_groups[r]=RectGroup.new(air)
				end
			end
		end
	end
end
