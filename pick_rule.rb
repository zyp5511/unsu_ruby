require_relative 'transform'
require_relative 'transform_old'
require 'set'


fcore_name = ARGV[0]#"../../res/core_head_clusters_52.txt";
fhead_name = ARGV[1]#"../../res/head_clusters_52.txt"
frules= "/home/lichao/scratch/recheck/net2_raw.txt"#"/home/lichao/research/posecpp/geo/geostd_with_mean.txt"
foutput_name = "rules.txt"

cores= IO.foreach(fcore_name).to_a.map(&:to_i).to_set
heads= IO.foreach(fhead_name).to_a.map(&:to_i).to_set
LCTransformTable.loadTable(frules,heads,cores)
