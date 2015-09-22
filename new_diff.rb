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

	opts.on("-t", "--threshold [VALUE]",Float, "threshold on annotation(I know it's wired)") do |v|
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

	opts.on("-o", "--output FILENAME", "output file") do |v|
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

	opts.on("--fnwidth [VALUE]", Float, "false negative width ") do |v|
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
	puts "annotation threshold #{tt} is given"
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|x.dis>tt}]}] 
elsif options.has_key?(:annotheight)
	tt = options[:annotheight]
	puts "annotation hieght lower bound #{tt} is given"
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|x.h>tt}]}] 
else
	cvrecords = Hash[Record::seperate_records(src,IO.foreach(cvdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
end

puts "start processing file:#{lcdat}"
# record filter 
record_choosers = []
if options.has_key?(:th2)
	puts "threshold of predication #{options[:th2]} is given"
	record_choosers << ->(x){x.dis>options[:th2]}
end

if options.has_key?(:predheight)
	tt2 = options[:predheight]
	puts "threshold of predication height #{options[:predheight]} is given"
	record_choosers << ->(x){x.h>options[:predheight] }
end

if record_choosers.size>0
	puts "threshold of predication #{tt2} is given"
	lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects.select{|x|record_choosers.all?{|y|y.call(x)}}]}] 
else
	lcrecords = Hash[Record::seperate_records(src,IO.foreach(lcdat),Record::parsers[:cv]).map{|r|[r.filename, r.rects]}] 
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

fphist = {};
tphist = {};

def draw_rect(ori,cvr)
	begin
		rdraw = Magick::Draw.new
		rdraw.stroke('yellow').stroke_width(0.5)
		rdraw.fill("transparent")
		rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
		#rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.type.to_s)
		rdraw.text(cvr.x+1,cvr.y+1,cvr.type.to_s) if !cvr.type.nil?
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


if options.has_key?(:fnwidth)
	puts "false negative threshold #{options[:fnwidth]} used"
	wt = options[:fnwidth]
end

lcrecords.each do |k,v|
	ori = Magick::Image.read(File.join(src,k).to_s).first
	oscimg =  ori.clone
	tp_img =  ori.clone
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
				draw_rect(ori,cvr)
			else
				# matched
				#tprect << cvr
				vid.each{|r| tprect<<r}
				tpfound = true;
				draw_rect(tp_img,cvr)
				vid.each{|g|matched[g] = true;draw_rect(tp_img,g)}
				if vid.length > 1
					puts "multiple matches in #{k}" if options.has_key?(:info)
				end
				inter_c+=vid.first.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
				inter+=1
				if options.has_key?(:debug)
					begin
						g_types = vid.first.type[1...-1].split(',').map(&:to_i)
					rescue Exception => e
						puts "=======================Error!====================="
						puts g_types.inspect
						puts e.backtrace.join("\n")
						puts "=======================Error!====================="
					end
					g_types.each do |atype|
						if tphist.has_key?(atype)
							tphist[atype]+=1
						else
							tphist[atype]=1
						end
					end
				end
			end
		end
		if fnfound
			# export missing faces
			ori.write(File.join(des,'fn',k).to_s)
		end
		if tpfound
			# export missing faces
			tp_img.write(File.join(des,'tp',k).to_s)
		end
	else 
		puts "postive annotatio not found for image #{k}" if options.has_key?(:info)
	end
	v.select{|x|!matched[x]}.each do |g|
		#export false alert
		fprect<<g;
		if options.has_key?(:debug)
			begin
				g_types = g.type[1...-1].split(',').map(&:to_i)
			rescue Exception => e
				puts "=======================Error!====================="
				puts g_types.inspect
				puts g.type.inspect
				puts e.backtrace.join("\n")
				puts "=======================Error!====================="
			end
			g_types.each do |atype|
				if fphist.has_key?(atype)
					fphist[atype]+=1
				else
					fphist[atype]=1
				end
			end
		end
		draw_rect(oscimg,g)
	end
	osctemp=v.length-v.select{|x|matched[x]}.length;
	osc+= osctemp
	## plot FP count
	rdraw = Magick::Draw.new
	rdraw.stroke('yellow').stroke_width(1)
	rdraw.text(16,16,osctemp.to_s)
	rdraw.draw(oscimg)
	## FP draw
	oscimg.write(File.join(des,"fp",k).to_s) if osctemp>0

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
	if options.has_key?(:debug)
		File.open(File.join(des,'fphist.txt'),"w") do |f|
			fphist.each do |k,v|
				f.puts "#{k}\t:\t#{v}"
			end
		end
		File.open(File.join(des,'tphist.txt'),"w") do |f|
			tphist.each do |k,v|
				f.puts "#{k}\t:\t#{v}"
			end
		end
	end
end

puts "extra missing #{cso_extra}"
cso+=cso_extra
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

