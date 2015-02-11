require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

#Jalali Experiment
#

src = ARGV[0]
des = ARGV[1]
astlcdat = ARGV[2]
lcdat = ARGV[3]
headdat = ARGV[4]
transfn = ARGV[5]

table = LCTransformTable.loadMap(transfn,1006) #hard coded cluster number, should be changed later
head = IO.readlines(headdat).map{|x|x.to_i}.to_set

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}]
	end
end

lcrecords= Hash[parse_cv_data lcdat]
astlcrecords= Hash[parse_cv_data astlcdat]

puts "there are #{lcrecords.length} records"

cso=0
osc=0
inter=0


fndir = File.join(des,'fn')
if !File.directory?(fndir)
	FileUtils.mkdir(fndir)
end

fpdir = File.join(des,'fp')
if !File.directory?(fpdir)
	FileUtils.mkdir(fpdir)
end

lcrecords.each do |k,v|
	ori = Magick::Image.read(File.join(src,k.gsub(/jpg/,"jp2")).to_s).first
	w = ori.columns;
	h = ori.rows;
	if (h>300)
		newh = 300;
		neww = w * 300 / h;
		ori.resize!(neww,newh);
	end

	oscimg =  ori.clone

	vv = v.map{|orir|table.transform orir};
	if astlcrecords[k]!=nil
		found = false
		astlcrecords[k].each do |cvr|
			vid = vv.select{|vr| vr.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
			if vid.size==0
				# miss found
				cso+=1
				found = true;
				rdraw = Magick::Draw.new
				rdraw.stroke('yellow').stroke_width(0.5)
				rdraw.fill("transparent")
				rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
				rdraw.draw(ori)
			else
				#matched
				vid.each{|g|g.matched = true;}
				inter+=1
			end
		end
		if found
			#export missing faces
			ori.write(File.join(des,'fn',k).to_s)
		end
	else 
		puts "CV records not found for #{k}"
	end
	vv.select{|x|!x.matched}.each do |vvr|
		#export false alert
		vrdraw = Magick::Draw.new
		vrdraw.stroke('red').stroke_width(0.5)
		vrdraw.fill("transparent")
		vrdraw.rectangle(vvr.x,vvr.y,vvr.x+vvr.w-1,vvr.y+vvr.h-1)
		vrdraw.text(vvr.x+1,vvr.y+vvr.h-20,vvr.type.to_s)
		vrdraw.draw(oscimg)
	end
	osc+= vv.size-vv.select{|x|x.matched}.size;
	oscimg.write(File.join(des,"fp",k).to_s) if found
end


#astlcrecords.each{|k,v| cso+=v.size if !cv_processed.include? k}
puts "True Positive: #{inter}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

