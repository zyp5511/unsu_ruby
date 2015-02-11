require_relative 'rect'
require 'set'

class LCTransform
	include Comparable
	attr_accessor :from, :to, :xr, :yr, :r, 
		:vx, :vy, :vr
	attr_accessor :derived
	attr_accessor :reliability # sum of relative standard variance
	def initialize(from, to, xr, yr, r,avx=1,avy=1,avr=1,derived=false,rel=100000)
		@from = from;
		@to = to;
		@xr = xr;
		@yr = yr;
		@r = r;
		@vx = avx;
		@vy = avy;
		@vr = avr;
		@derived=derived;
		if !@derived
			@reliability = Math.sqrt(@vx)/@r.abs+
				Math.sqrt(@vy)/@r.abs+
				Math.sqrt(@vr)/@r.abs
		else 
			@reliability = rel;
		end
	end

	#load old formatted line
	def self.load (str)
		from_str,to_str,xr_str,yr_str,r_str = str.split(/=>|:|\s/).map(&:chomp)
		LCTransform.new(from_str.to_i,to_str.to_i,xr_str.to_f,yr_str.to_f,r_str.to_f)
	end

	#load newly formatted line with var info
	def self.loadTable (str)
		fromto_str,c_str,vx_str,vy_str,vr_str,mx_str,my_str,mr_str = str.split(/\s/).map(&:chomp)
		ft_i = fromto_str.to_i
		f_i = ft_i/10000;
		t_i = ft_i%10000;
		LCTransform.new(f_i,t_i,mx_str.to_f,my_str.to_f,mr_str.to_f,
						vx_str.to_f,vy_str.to_f,vr_str.to_f)
	end
	def self.extract ri, rj
		ii = ri.type
		jj = rj.type
		xx = (rj.x - ri.x+0.0)/ri.w
		yy = (rj.y - ri.y+0.0)/ri.h
		rr = (rj.h + 0.0)/ri.h
		LCTransform.new(ii,jj,xx,yy,rr)
	end

	def transform rect 
		x = rect.x + @xr * rect.w
		y = rect.y + @yr * rect.h
		w = rect.w * @r
		h = rect.h * @r
		Rect.new(rect.type,rect.dis,x.to_i,y.to_i,w.to_i,h.to_i)
	end

	def transform_with_type rect 
		x = rect.x + @xr * rect.w
		y = rect.y + @yr * rect.h
		w = rect.w * @r
		h = rect.h * @r
		Rect.new(@to,rect.dis,x.to_i,y.to_i,w.to_i,h.to_i)
	end

	def to_s
		"#{@from}=>#{@to}\t#{@xr}:#{@yr}:#{@r}\t#{@vx}:#{@vy}:#{@vr}\t#{"derived" if @derived}\t#{@reliability}"
	end

	def to_short_s
		"#{@from}=>#{@to}\t#{@xr}:#{@yr}:#{@r}"
	end

	def to_tsv_s
		"#{@from}\t#{@to}\t#{@xr}\t#{@yr}\t#{@r}"
	end

	# inverse transform
	def inv
		LCTransform.new(@to,@from,-@xr/@r,-@yr/@r,1/@r, @vx/@r/@r,@vy/@r/@r,@vr,true,@reliability)
	end

	def <=>(other)# for sorting
		comparision = r <=> other.r
		if comparision == 0
			return xr <=>other.xr
		else
			return comparision
		end
	end
	def +(other)# for average calculation
		LCTransform.new(from,to,xr+other.xr,yr+other.yr,r+other.r)
	end
	def /(n)
		LCTransform.new(from,to,xr/n,yr/n,r/n)
	end
end

class LCTransformSet
	def initialize(transforms)
		@transforms = transforms
		@simplify_approaches ={
			median: ->(rules){rules[rules.size/2]},
			avg:->(rules)do
				if rules.size<3
					return rules[0]
				else 
					rules[1...-1].inject(:+)/(rules.size-2)
				end
			end
		}
	end

	def self.loadAll(fname)
		trans = Array.new
		IO.foreach(fname) do |line|
			trans << LCTransform.load(line) if line =~ /=>/
		end
		LCTransformSet.new(trans)
	end

	def simplify (appr,id=594)# rule extraction using different lambda
		@transforms.group_by{|t| t.from }.flat_map do |kf,fg|
			fg.group_by{|tt| tt.to}.select{|k,v| k==id}.map do |kt,tg| 
				sorted_tg = tg.sort
				@simplify_approaches[appr].call(sorted_tg)
			end
		end
	end
end

class LCTransformTable 
	def initialize(transforms)
		@transforms = transforms
	end

	def transform rect
		t = @transforms[rect.type]
		if t!=nil
			t.transform rect
		else
			rect
		end
	end	

	def self.loadTable(fname,src,des)
		trans = Hash.new{|h,k|h[k]=[]}
		srctrimmed = src-des;
		IO.foreach(fname) do |line|
			rule = LCTransform.loadTable(line) 
			if (des.include?(rule.to) && srctrimmed.include?(rule.from)) 
				trans[rule.from] << rule  
			end
			if (des.include?(rule.from) && srctrimmed.include?(rule.to))
				trans[rule.to] << rule.inv
			end
		end
		b = Hash[trans.map{|k,v|[k,v.min_by{|x|x.reliability}]}]
		#File.open("cluster_rules_cand.txt", "w") do |file|
		#	trans.each do |k,v|
		#		file.puts "#{k}:"
		#		v.each{|r|file.puts "\t#{r}"}
		#		file.puts
		#	end 
		#end 
		#File.open("52cluster_rules_selection.txt", "w") do |file|
		#	b.each do |k,v|
		#		file.puts "#{k}:#{v.to}"
		#		file.puts
		#	end 
		#end

		File.open("rules.txt", "w") do |file|
			b.each do |k,v|
				file.puts "#{v.to_short_s}"
			end 
		end
	end
	def self.loadMap(fname,n)
		trans = Array.new(n);
		IO.foreach(fname) do |line|
			t = LCTransform.load(line)
			trans[t.from] = t;
		end
		LCTransformTable.new(trans)
	end
end


#class LCTransformFullTable 
#	#pick best rules from each outier nodes to core nodes
#	attr_accessor :table
#	def initialize ahash
#		@table = ahash
#		@goodset = Set.new;
#	end
#	def query from,to
#		if from == to
#			return LCTransform.new(from,from,0,0,1)
#		end
#		target = from*10000+to
#		invtarget= to*10000+from
#		if @goodset.length>0
#			if @goodset.include?(target)||@goodset.include?(invtarget)
#				return @table[target]
#			else 
#				return nil
#			end
#		else 
#			return @table[target]
#		end 
#
#	end
#	def restrict fname
#		IO.foreach(fname) do |line|
#			good=line.split.map(&:to_i)
#			@goodset<<(good[0]*10000+good[1])
#		end
#	end
#
#	def self.loadTable(fname)
#		trans= Hash.new
#		IO.foreach(fname) do |line|
#			rule = LCTransform.loadTable(line) 
#			trans[rule.from*10000+rule.to] = rule  
#			trans[rule.to*10000+rule.from] = rule.inv 
#		end
#		LCTransformFullTable.new(trans)
#	end
#end
