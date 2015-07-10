require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'
require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: new_diff.rb [options]"
	opts.on("-s", "--source DIRNAME", "Image Directory") do |v|
		options[:source] = v
	end

	opts.on("-a", "--annotation FILENAME", "record file") do |v|
		options[:annotation] = v
	end

	opts.on("-p", "--predication FILENAME", "head node list file") do |v|
		options[:predication] = v
	end

	opts.on("-t", "--threshold [VALUE]",Float, "transform file") do |v|
		options[:threshold] = v
	end

	opts.on("-o", "--output FILENAME", "output file") do |v|
		options[:output] = v
	end

	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end

	opts.on("-h", "--help", "Prints this help") do
		puts opts
		exit
	end
end.parse!

src = options[:source]
des = options[:output]
cvdat = options[:annotation]
lcdat = options[:predication]

# threshold for poselets: 3.6 added
if options.has_key?(:threshold)
	tt = options[:threshold]
	puts "threshold #{tt} is given"
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|x.dis>tt}]}] 
else
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
end
lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 

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

fnrect = [];
fprect = [];
tprect = [];

def draw_rect(ori,cvr)
	begin
		rdraw = Magick::Draw.new
		rdraw.stroke('yellow').stroke_width(0.5)
		rdraw.fill("transparent")
		rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
		#rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.type.to_s)
		rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.dis.to_s) if !cvr.dis.nil?
		rdraw.draw(ori)
	rescue Exception => e
		puts "draw_rect=======================Error!====================="
		puts cvr.inspect
		puts e.backtrace.join("\n")
		puts "process_rect=======================Error!====================="
	end

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
				fnrect << cvr
				cso+=1
				found = true;
				draw_rect(ori,cvr)
			else
				# matched
				tprect << cvr
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
if !options[:verbose].nil? and options[:verbose]
	puts "outputing in verbose mode"

	File.open(File.join(des,'fnstat.txt'),"w") do |f|
		fnrect.each do |r|
			f.puts "#{r.w}\t#{r.h}\t#{r.dis}"
		end
	end
	File.open(File.join(des,'tpstat.txt'),"w") do |f|
		tprect.each do |r|
			f.puts "#{r.w}\t#{r.h}\t#{r.dis}"
		end
	end
end

puts "extra missing #{cso_extra}"
cso+=cso_extra
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

