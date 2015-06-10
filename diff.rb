require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'

src = ARGV[0]
des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]
headdat = ARGV[4]
transfn = ARGV[5]

table = LCTransformTable.loadMap(transfn,1006) #hard coded cluster number, should be changed later
head = IO.readlines(headdat).map{|x|x.to_i}.to_set

cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:origin]).select{|r|r.rects!=nil}.each{|r|r.pick_good_set head;r.group_rects table}.select{|r|r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{lcrecords.length} records"

cso=0
osc=0
inter=0
inter_c=0

tphist = Array.new(1006,0) #hard coded cluster count
fphist = Array.new(1006,0) #hard coded cluster count

tcthist= Array.new(1000,0) 
fcthist= Array.new(1000,0) 

if !File.directory?(des)
	FileUtils.mkdir(des)
end


fndir = File.join(des,'fn')
if !File.directory?(fndir)
	FileUtils.mkdir(fndir)
end

fpdir = File.join(des,'fp')
if !File.directory?(fpdir)
	FileUtils.mkdir(fpdir)
end

def draw_rect(ori,cvr)
	rdraw = Magick::Draw.new
	rdraw.stroke('yellow').stroke_width(0.5)
	rdraw.fill("transparent")
	rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
	#rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.type.to_s)
	rdraw.draw(ori)
end

cv_processed = Set.new()


lcrecords.each do |k,v|
	ori = Magick::Image.read(File.join(src,k).to_s).first
	oscimg =  ori.clone

	group_set = v.groups.values.to_set
	group_set.each do |g|
		g.aggregate
	end

	vg=group_set.select{|y|y.rects.length>1}
	found = false
	if !cvrecords[k].nil?
		cv_processed << k;
		cvrecords[k].each do |cvr|
			vid = vg.select{|vr| vr.aggregated_rect.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
			if vid.length==0
				# miss found
				cso+=1
				found = true;
				draw_rect(ori,cvr)
			else
				# matched
				vid.each{|g|g.matched = true;}
				inter_c+=vid.first.aggregated_rect.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
				inter+=1
			end
		end
		if found
			# export missing faces
			ori.write(File.join(des,'fn',k).to_s)
		end
	else 
		puts "CV records not found for #{k}"
	end
	#vv.select{|x|x.matched}.each{|vvr|tphist[vvr.type]+=1}
	vg.select{|x|x.matched}.each do |g|
		tcthist[g.rects.length]+=1
	end
	vg.select{|x|!x.matched}.each do |g|
		#export false alert
		fcthist[g.rects.length]+=1;
		draw_rect(oscimg,g.aggregated_rect)
	end
	osctemp= vg.length-vg.select{|x|x.matched}.length;
	osc+= osctemp
	## FP draw
	oscimg.write(File.join(des,"fp",k).to_s) if osctemp>0
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

cso_extra=0;
cvrecords.each do |k,v| 
	if !cv_processed.include? k
		cso_extra+=v.length 
	end
end
puts "extra missing #{cso_extra}"
cso+=cso_extra
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

