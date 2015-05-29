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
