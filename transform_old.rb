require_relative 'rect'
require_relative 'transform'
require 'set'

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
		if !t.nil?
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


