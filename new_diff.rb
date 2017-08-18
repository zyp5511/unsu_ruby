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

	opts.on("-t", "--threshold [VALUE]",Float, "threshold on annotation (I know it's wired)") do |v|
		options[:threshold] = v
	end

	opts.on("--annotheight [VALUE]",Float, "threshold height lower bound") do |v|
		options[:annotheight] = v
	end

	opts.on("--predheight [VALUE]",Float, "predication threshold height lower bound") do |v|
		options[:predheight] = v
	end

	opts.on("--th2 [VALUE]",Float, "threshold of predication to be compared") do |v|
		options[:th2] = v
	end

	opts.on("-o", "--output FILENAME", "output directory") do |v|
		options[:output] = v
	end

	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end

	opts.on("--info", "Run extreme verbosely") do |v|
		options[:info] = true
	end

	opts.on("--debug", "Run in debug mode") do |v|
		options[:debug] = v
	end

	opts.on("--plot", "Plot the result") do |v|
		options[:plot] = v
	end

	opts.on("--crop", "Crop the result") do |v|
		options[:crop] = v
	end

	opts.on("--fnwidth [VALUE]", Float, "false negative width ") do |v| #deprecated
		options[:fnwidth] = v
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

# anntation filter
if options.has_key?(:threshold)
	tt = options[:threshold]
	puts "annotation score threshold #{tt} is given"
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|x.dis>tt}]}] 
elsif options.has_key?(:annotheight)
	tt = options[:annotheight]
	puts "annotation height lower bound #{tt} is given"
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|x.h>tt}]}] 
else
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
end

puts "start processing file:#{lcdat}"

# record filter 
#
record_choosers = []
if options.has_key?(:th2)
	puts "predication score threshold #{options[:th2]} is given"
	record_choosers << ->(x){x.dis>options[:th2]}
end

if options.has_key?(:predheight)
	puts "predication height threshold #{options[:predheight]} is given"
	tt2 = options[:predheight]
	record_choosers << ->(x){x.h>options[:predheight] }
end

if record_choosers.size>0
	puts "threshold of predication #{tt2} is given"
	lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|record_choosers.all?{|y|y.call(x)}}]}] 
else
	lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
end

#Deprecated: false negative threshold
if options.has_key?(:fnwidth)
	puts "false negative threshold #{options[:fnwidth]} used"
	wt = options[:fnwidth]
end

puts "there are #{lcrecords.length} records" if options.has_key?(:info)

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

tpdir = File.join(des,'tp')
if !File.directory?(tpdir)
	FileUtils.mkdir(tpdir)
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
		rdraw.text(cvr.x+1,cvr.y+1,cvr.type.to_s.inspect) if !cvr.type.nil?
		rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.dis.to_s.inspect) if !cvr.dis.nil?
		rdraw.draw(ori)
	rescue Exception => e
		puts "draw_rect=======================Error!====================="
		puts cvr.inspect
		puts e.backtrace.join("\n")
		puts "process_rect=======================Error!====================="
	end

end

def crop_rect(ori,rect,subdir,filename)
	temp = ori.crop(rect.x,rect.y,rect.w,rect.h,true)
	#type = rect.type
	temp.write("#{File.join(subdir,File.basename(filename, File.extname(filename))).to_s}_#{rect.x}+#{rect.y}+#{rect.w}x#{rect.h}#{File.extname(filename)}")
end

cv_processed = Set.new()



lcrecords.each do |k,v|
	if options.has_key?(:plot) or options.has_key?(:crop)
		ori = Magick::Image.read(File.join(src,k).to_s).first
		oscimg =  ori.clone
		tp_img =  ori.clone
	end
	fnfound = false
	tpfound = false
	matched = Hash.new
	fnrect<<k;
	tprect<<k;
	fprect<<k;
	if !cvrecords[k].nil?
		cv_processed << k;
		cvrecords[k].each do |cvr|
			vid = v.select{|vr| vr.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
			if vid.length==0
				# miss found
				#
				# record missing with small size
				if options.has_key?(:fnwidth)
					fnrect << cvr if cvr.w < wt
				else
					fnrect << cvr
				end
				cso+=1
				fnfound = true;
				if options.has_key?(:plot)
					draw_rect(ori,cvr)
				end
			else
				# matched
				#tprect << cvr
				vid.each{|r| tprect<<r}
				tpfound = true;
				vid.each{|g|matched[g] = true}
				if options.has_key?(:plot)
					draw_rect(tp_img,cvr)
					vid.each{|g|draw_rect(tp_img,g)}
				elsif options.has_key?(:crop)
					vid.each{|g|crop_rect(tp_img,g,tpdir,k)}
				end
				if vid.length > 1
					puts "multiple matches in #{k}" if options.has_key?(:info)
				end
				inter_c+=vid.first.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
				inter+=1
			end
		end
		if options.has_key?(:plot)
			if fnfound
				# export missing faces
				ori.write(File.join(des,'fn',k).to_s)
			end
			if tpfound
				# export missing faces
				tp_img.write(File.join(des,'tp',k).to_s)
			end
		end
	else 
		puts "postive annotatio not found for image #{k}" if options.has_key?(:info)
	end
	v.select{|x|!matched[x]}.each do |g|
		#export false alert
		fprect<<g;
		if options.has_key?(:plot)
			draw_rect(oscimg,g)
		elsif options.has_key?(:crop)
			crop_rect(oscimg,g,fpdir,k)
		end
	end
	osctemp=v.length-v.select{|x|matched[x]}.length;
	osc+= osctemp
	## plot FP count
	if options.has_key?(:plot)
		rdraw = Magick::Draw.new
		rdraw.stroke('yellow').stroke_width(1)
		rdraw.text(16,16,osctemp.to_s.inspect)
		rdraw.draw(oscimg)
		## FP draw
		oscimg.write(File.join(des,"fp",k).to_s) if osctemp>0
	end

	## remove empty records
	if fnrect[-1]==k
		fnrect.pop
	end
	if tprect[-1]==k
		tprect.pop
	end
	if fprect[-1]==k
		fprect.pop
	end
end

cso_extra=0;
cvrecords.each do |k,v| 
	if !cv_processed.include? k
		cso_extra+=v.length 
		if (v.length>0)
			fnrect<<k;
			ori = Magick::Image.read(File.join(src,k).to_s).first
			cvrecords[k].each{|cvr|fnrect<<k;draw_rect(ori,cvr)}
			ori.write(File.join(des,'fn',k).to_s)
		end
	end
end

if !options[:verbose].nil? and options[:verbose]
	puts "outputing in verbose mode"
	File.open(File.join(des,'fnstat.txt'),"w") do |f|
		fnrect.each do |r|
			if r.instance_of?(Rect)
				#f.puts "#{r.w}\t#{r.h}\t#{r.dis}"
				f.puts r.to_s
			else
				f.puts r;
			end
		end
	end
	File.open(File.join(des,'tpstat.txt'),"w") do |f|
		tprect.each do |r|
			if r.instance_of?(Rect)
				#f.puts "#{r.w}\t#{r.h}\t#{r.dis}"
				f.puts r.to_s
			else
				f.puts r;
			end
		end
	end

	fpcount = 0;
	File.open(File.join(des,'fpstat.txt'),"w") do |f|
		fprect.each do |r|
			if r.instance_of?(Rect)
				#f.puts "#{r.w}\t#{r.h}\t#{r.dis}"
				f.puts r.to_s
				fpcount+=1
			else
				f.puts fpcount;
				f.puts r;
				fpcount = 0;
			end
		end
	end
end

cso+=cso_extra
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"
puts "Extra missing #{cso_extra}"

