require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

src = ARGV[0]
des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]
headdat = ARGV[4]
transfn = ARGV[5]
netfn = ARGV[6]
elfn = ARGV[7]

nettable = LCTransformFullTable.loadTable(netfn) #hard coded cluster number, should be changed later
nettable.restrict elfn

table = LCTransformTable.loadMap(transfn,1006) #hard coded cluster number, should be changed later
head = IO.readlines(headdat).map{|x|x.to_i}.to_set

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}]
	end
end

cvrecords = Hash[parse_cv_data cvdat]
#lcrecords = Hash[Record::seperate_records(src,des,IO.foreach(lcdat)).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects_with_graph  nettable,table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 
lcrecords = Hash[Record::seperate_records(src,des,IO.foreach(lcdat)).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{lcrecords.length} records"

cso=0
osc=0
inter=0
inter_c=0

tphist = Array.new(1006,0) #hard coded cluster count
fphist = Array.new(1006,0) #hard coded cluster count

tcthist= Array.new(1000,0) 
fcthist= Array.new(1000,0) 

#fndir = File.join(des,'fn')
#if !File.directory?(fndir)
#	FileUtils.mkdir(fndir)
#end
#
#fpdir = File.join(des,'fp')
#if !File.directory?(fpdir)
#	FileUtils.mkdir(fpdir)
#end

cv_processed = Set.new()
lcrecords.each do |k,v|
	#ori = Magick::Image.read(File.join(src,k).to_s).first
	#oscimg =  ori.clone

	v.groups.values.to_set.each do |g|
			#g.aggregate_with_table nettable
			#g.reset_infer table
			g.aggregate
	end
	#vg = v.groups.values.to_set
	vg=v.groups.values.to_set.select{|y|y.rects.length>1}

	if cvrecords[k]!=nil
		cv_processed << k;
		found = false
		cvrecords[k].each do |cvr|
			vid = vg.select{|vr| vr.aggregated_rect.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
			if vid.size==0
				# miss found
				cso+=1
				found = true;
				#rdraw = Magick::Draw.new
				#rdraw.stroke('yellow').stroke_width(0.5)
				#rdraw.fill("transparent")
				#rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
				#rdraw.draw(ori)
			else
				#matched
				vid.each{|g|g.matched = true;}
				inter_c+=vid.first.aggregated_rect.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
				inter+=1
			end
		end
		if found
			#export missing faces
			#ori.write(File.join(des,'fn',k).to_s)
		end
	else 
		puts "CV records not found for #{k}"
	end
	found = false;
	#vv.select{|x|x.matched}.each{|vvr|tphist[vvr.type]+=1}
	vg.select{|x|x.matched}.each do |g|
		tcthist[g.rects.length]+=1
	end
	vg.select{|x|!x.matched}.each do |g|
		#export false alert
		fcthist[g.rects.length]+=1;
		#vrdraw = Magick::Draw.new
		#vrdraw.stroke('red').stroke_width(0.5)
		#vrdraw.fill("transparent")
		#vrdraw.rectangle(vvr.x,vvr.y,vvr.x+vvr.w-1,vvr.y+vvr.h-1)
		#vrdraw.text(vvr.x+1,vvr.y+vvr.h-20,vvr.type.to_s)
		#vrdraw.draw(oscimg)
	end
	osc+= vg.size-vg.select{|x|x.matched}.size;
	#oscimg.write(File.join(des,"fp",k).to_s) if found
end

File.open(File.join(des,'tcthist.txt'),"w") do |f|
	tcthist.each_with_index{|x,i| f.puts "#{i}\t#{x}"}
end
File.open(File.join(des,'fcthist.txt'),"w") do |f|
	fcthist.each_with_index{|x,i| f.puts "#{i}\t#{x}"}
end

#File.open(File.join(des,'tphist.txt'),"w") do |f|
#	tphist.each_with_index{|x,i| f.puts "#{i}\t#{x}"}
#end
#File.open(File.join(des,'fphist.txt'),"w") do |f|
#	fphist.each_with_index{|x,i| f.puts "#{i}\t#{x}"}
#end

cvrecords.each{|k,v| cso+=v.size if !cv_processed.include? k}
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

