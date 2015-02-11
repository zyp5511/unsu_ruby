require 'fileutils'
require 'set'

require 'rgl/adjacency'
require 'rgl/traversal'
require 'rgl/dot'
require 'rgl/connected_components'
#require 'rgl/edge_properties_map'

require_relative 'rect_group'
require_relative 'transform'

class Network
	#pick best rules from each outier nodes to core nodes
	attr_accessor :table
	attr_accessor :distances 
	attr_accessor :graph
	attr_accessor :good_set #edgelist, table has all n(n-1)/2 pairs

	def subgraph_quality(nodeset)
		tot = 0;
		nodeset.each do |n|
			if @distances[n]!=nil
				@distances[n].each do |k,d|
					if nodeset.include?(k)
					   tot+=d;	
					end
				end
			end
		end
		tot

	end

	def initialize ahash
		@table = ahash
		@good_set = Set.new;
		#@distances = {}
	end


	def query from,to
		if from == to
			return LCTransform.new(from,from,0,0,1)
		end
		target = from*10000+to
		invtarget= to*10000+from
		#if @good_set.length>0  ## stupid implementation, super slow
		if !@good_set.empty?
			if @good_set.include?(target)||@good_set.include?(invtarget)
				return @table[target]
			else 
				return nil
			end
		else 
			return @table[target]
		end 

	end

	#def set_distance i,j,d #store each val twice for easier node iteration
	#	i,j=j,i if i>j
	#	if @distances[i]==nil
	#		@distances[i]= {}
	#	end
	#	if @distances[j]==nil
	#		@distances[j]= {}
	#	end
	#	@distances[i][j]=d
	#	@distances[j][i]=d
	#end

	#def get_distance i,j
	#	i,j=j,i if i>j
	#	if @distances[i]!=nil
	#		@distances[i][j]
	#	else
	#		nil
	#	end
	#end
	def restrict fname
		@graph = RGL::AdjacencyGraph.new
		@nodes = Set.new
		IO.foreach(fname) do |line|
			good=line.split.map(&:to_i)
			@graph.add_edge(good[0],good[1])
			@nodes << good[0]
			@nodes << good[1]
			if good[0]<good[1]
				@good_set<<(good[0]*10000+good[1])
			else
				@good_set<<(good[1]*10000+good[0])
			end
		#	set_distance good[0],good[1],1
		end
		#nodes_array = @nodes.sort
		#for k in 0...(nodes_array.length)
		#	for i in 0...(nodes_array.length-1)
		#		if i!=k
		#			for j in (i+1)...(nodes_array.length)
		#				if j!=k
		#					dik=get_distance(i,k)
		#					dkj=get_distance(k,j)
		#					dij=get_distance(i,j)
		#					if (dik!=nil and dkj!=nil) and (dij==nil or dij>dkj+dik)
		#						set_distance(i,j,dkj+dik)
		#					end
		#				end
		#			end
		#		end
		#	end
		#end
	end

	def self.loadTable(fname)
		trans= Hash.new
		IO.foreach(fname) do |line|
			rule = LCTransform.loadTable(line) 
			trans[rule.from*10000+rule.to] = rule  
			trans[rule.to*10000+rule.from] = rule.inv 
		end
		Network.new(trans)
	end
end
