require_relative 'rect'
require_relative 'point'

class RectGroup
	attr_accessor :rects
	attr_accessor :matched
	attr_accessor :originx, :originy
	attr_accessor :originsx,:originsy # global unit length in pix
	@@originmx = nil
	@@originmy = nil

	def initialize arect=nil
		matched = false
		if arect!=nil
			@rects=[arect]
		else
			@rects=[]
		end
	end

	def self.merge ga,gb
		arects=ga.rects+gb.rects

		res = RectGroup.new 
		res.rects = arects

		alpha = ga.rects.length;
		beta = gb.rects.length;
		res.originx = ( ga.originx*alpha+gb.originx*beta)/(alpha+beta)
		res.originy = ( ga.originy*alpha+gb.originy*beta)/(alpha+beta)
		res.originsx = ( ga.originsx*alpha+gb.originsx*beta)/(alpha+beta)
		res.originsy = ( ga.originsy*alpha+gb.originsy*beta)/(alpha+beta)
		res
	end

	def compatible?(gb)
		dx = (@originx-gb.originx).abs
		dy = (@originy-gb.originy).abs
		ds = (Math.log(@originsy)-Math.log(gb.originsy)).abs
		#stdx = @originsx+gb.originsx
		#stdy = @originsy+gb.originsy
		stdx = @@originmx * (@originsx + gb.originsx)
		stdy = @@originmy * (@originsy + gb.originsy)

		if (dx<stdx*0.1) && (dy<stdy*0.1) && (ds<0.2)
			true
		else
			false
		end
	end

	def abs2gbl arect
		begin
			[(arect.x-@originx)/@originsx, (arect.y-@originy)/@originsy, (arect.w)/@originsx]
		rescue Exception => e
			puts e.backtrace
			puts "arect is #{arect}"
		end
	end

	def infer_part_globally global_table,n_index
		pt = global_table[n_index] 
		if pt !=nil
			res = Rect.new(n_index,0,pt.x*@originsx+@originx,pt.y*@originsy+@originy,pt.s*@originsx,pt.s*@originsy)
		else 
			raise "Entry not exist in global table"
		end
	end

	def calibrate_global global_table
		#puts "==============================="
		xs=[];ys=[];
		as=[];bs=[];ss=[];
		ssy=[];
		
		if @@originmx == nil
			tempxmax = global_table.values.max_by{|n|n.x}.x
			tempxmin= global_table.values.min_by{|n|n.x}.x
			@@originmx = tempxmax - tempxmin

			tempymax = global_table.values.max_by{|n|n.y}.y
			tempymin= global_table.values.min_by{|n|n.y}.y
			@@originmy = tempymax - tempymin

			puts "global x span is #{@@originmx}; global y span is #{@@originmy}"
		end

		@rects.each do |r|
			pt = global_table[r.type] 
			if pt !=nil
				xs << r.x
				ys << r.y
				as << pt.x
				bs << pt.y
				ss << r.w.to_f/pt.s
				ssy << r.h.to_f/pt.s
			else 
				#		puts "type #{r.type} not found"
			end
		end

		######################
		##Alternative Mathod##
		#avg_x = xs.inject(:+).to_f/xs.length 
		#avg_y = ys.inject(:+).to_f/ys.length 
		#avg_a = as.inject(:+).to_f/as.length 
		#avg_b = bs.inject(:+).to_f/bs.length 

		#sx = as.map{|a|a*(a-avg_a)}.inject(:+)/as.zip(xs).map{|a,x|a*(x-avg_x)}.inject(:+)
		#sy = bs.map{|b|b*(b-avg_b)}.inject(:+)/bs.zip(ys).map{|b,y|b*(y-avg_y)}.inject(:+)
		#
		#puts "avg_x is #{avg_x};avg_y is #{avg_y};avg_a is #{avg_a};avg_b is #{avg_b};" 
		######################

		@originsx = ss.inject(:+)/ss.length;
		@originsy = ssy.inject(:+)/ssy.length;
		@originx = as.zip(xs).map{|a,x|(x-@originsx*a)}.inject(:+)/xs.length
		@originy = bs.zip(ys).map{|b,y|(y-@originsy*b)}.inject(:+)/ys.length

		#puts "originsx is #{@originsx} originsy is #{@originsy}"
		#puts "origin_x is #{@originx}; origin_y is #{@originy}"
		#puts "==============================="
	end

	def include arect
		if !@rects.empty?
			return @rects.inject(false){|res,rec|res || (rec.include arect)}
		else 
			return false
		end
	end


	def add_rect ar
		@rects << ar;
	end


	def aggregate_with_table table
		if @rects.length > 1 
			itc = 0;
			loop do 
				#puts "===================="
				#puts "iteration #{itc}"
				sum_delta=0
				@rects.each_with_index{|x,i| sum_delta += adjust(i,table)}
				itc+=1
				if sum_delta<0.03||itc>5
					#puts "converged"
					break
				end
			end

		else 
			return nil
		end
	end

	def adjust i,table
		node = @rects[i]
		rest = @rects - [node];
		goodpairs= rest.map{|x| [(table.query x.type,node.type),x]}.reject{|x|x[0].nil?}
		if !goodpairs.empty?
			sumweight=goodpairs.map{|x|x[0].r*x[0].r}.inject(:+)
			adjr =goodpairs.map{|x| (x[0].transform_with_type x[1])*(x[0].r*x[0].r)}.inject{|s,x|s+=x}/sumweight
			difr = adjr - node;
			makeupr = difr/2;
			newadj = node + makeupr
			@rects[i]=newadj
		end
		0.01
	end
end
