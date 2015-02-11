# compare 2 standards tagging, which don't have transforms.
require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

src = ARGV[0]
des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("jpg")||l.end_with?("png") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}]
	end
end


cvrecords = Hash[parse_cv_data cvdat]
lcrecords = Hash[parse_cv_data lcdat]

cso=0
osc=0
inter=0

lcrecords.each do |k,v|
	ori = Magick::Image.read(File.join(src,k).to_s).first
	ratio=1;
	if ori.rows>300
		ratio  = ori.rows.to_f/300
	end
	oscimg =  ori.clone
	if cvrecords[k]!=nil
		found = false
		cvrecords[k].each do |cvr|
			begin
				cvr.x = cvr.x/ratio
				cvr.y = cvr.y/ratio
				cvr.w = cvr.w/ratio
				cvr.h = cvr.h/ratio
				vid = v.select{|vr| vr.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
				if vid.size==0
					cso+=1
					found = true;
					rdraw = Magick::Draw.new
					rdraw.stroke('yellow').stroke_width(0.5)
					rdraw.fill("transparent")
					rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
					rdraw.draw(ori)
				else
					vid.each{|x|x.matched=true};
					inter+=1
				end
			rescue
			end
		end
		if found
			ori.write(File.join(des,k).to_s)
		end
	else 
		#puts "CV records not found for #{k}"
	end
	found = false;
	v.select{|x|!x.matched}.each do |vvr|
		found = true;
		vrdraw = Magick::Draw.new
		vrdraw.stroke('red').stroke_width(0.5)
		vrdraw.fill("transparent")
		vrdraw.rectangle(vvr.x,vvr.y,vvr.x+vvr.w-1,vvr.y+vvr.h-1)
		vrdraw.draw(oscimg)
	end
	osc+= v.size-v.select{|x|x.matched}.size;
	oscimg.write(File.join(des,"win",k).to_s) if found
end
puts "True Positive: #{inter}\tMissing: #{cso}\tFalse Positive: #{osc}"
