require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'

src = ARGV[0]
des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}.to_set]
	end
end

cvrecords = Hash[parse_cv_data cvdat]
lcrecords = Hash[parse_cv_data lcdat]

puts "there are #{lcrecords.length} records"

cso=0
osc=0
inter=0
inter_c=0

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
	found = false
	matched = Hash.new
	if !cvrecords[k].nil?
		cv_processed << k;
		cvrecords[k].each do |cvr|
			vid = v.select{|vr| vr.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
			if vid.length==0
				# miss found
				cso+=1
				found = true;
				draw_rect(ori,cvr)
			else
				# matched
				vid.each{|g|matched[g] = true;}
				inter_c+=vid.first.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
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
	v.select{|x|!matched[x]}.each do |g|
		#export false alert
		draw_rect(oscimg,g)
	end
	osctemp=v.length-v.select{|x|matched[x]}.length;
	osc+= osctemp
	## FP draw
	oscimg.write(File.join(des,"fp",k).to_s) if osctemp>0
end

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

