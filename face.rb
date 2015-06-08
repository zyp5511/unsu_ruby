require 'set'
require 'rmagick'
require 'fileutils'

require_relative 'record'
require_relative 'network'

src = ARGV[0]
des = ARGV[1]
truth_fn = ARGV[2]
pred_fn = ARGV[3]
netfn = ARGV[4]
elfn = ARGV[5]
global_fn = ARGV[6]

nettable = Network.loadTable(netfn) #hard coded cluster number, should be changed later
nettable.restrict elfn
global_table=Point.loadGlobal(global_fn)

fndir = File.join(des,'fn')
if !File.directory?(fndir)
	FileUtils.mkdir(fndir)
end

fpdir = File.join(des,'fp')
if !File.directory?(fpdir)
	FileUtils.mkdir(fpdir)
end

def parse_cv_data fname
	IO.foreach(fname).map{|x|x.chomp}.chunk{|l|l.end_with?("gif")||l.end_with?("jpg")||l.end_with?("png")||l.end_with?("jpeg") }.each_slice(2).map do |a|
		[a[0][1][0], a[1][1].map{|x|Rect.makePureRect(x)}]
	end
end

truth_dat = Hash[parse_cv_data truth_fn]
pred_dat = Hash[Record::seperate_records(src,IO.foreach(pred_fn)).select{|r|r.rects!=nil}.each do |r|
	begin
		puts r.filename
		r.group_rects_with_graph  nettable
	rescue Exception => e
		puts e
	end
end.select{|r|!r.groups.nil? && r.groups.values.to_set.length>0}.map{|r|[r.filename, r]}] 

puts "there are #{pred_dat.length} records"

cso=0 #CV-ours: Missing
osc=0 #ours-CV: FP
inter=0 #: TP
inter_c=0 #: TP distance sum


if !File.directory?(des)
	FileUtils.mkdir(des)
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
pred_dat.each do |k,v|
	# load image and create copy for FP
	ori = Magick::Image.read(File.join(src,k).to_s).first
	oscimg =  ori.clone

	begin
		vgs=v.groups.values.to_set.select{|y|y.rects.map{|x|x.type}.to_set.length>1}
		vgs.each do |g|
			g.aggregate_with_table nettable
			g.calibrate_global global_table
			g.infer_part_globally(global_table,100)
		end

		if truth_dat[k]!=nil
			cv_processed << k;
			found = false
			# iterate all groundtruth annotations
			truth_dat[k].each do |cvr|
				matched_groups = vgs.select{|g| g.aggregated_rect.has_point cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)}
				if matched_groups.size==0
					# miss found
					cso+=1
					found = true;
					 draw_rect(ori,cvr)
				else
					#matched
					matched_groups.each{|g|g.matched = true;}
					inter_c+=matched_groups.first.aggregated_rect.distance_from cvr.x+(cvr.w/2),cvr.y+(cvr.h/2)
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
		found = false;
		vgs.select{|g|!g.matched}.each do |g|
			##export false alert
			draw_rect(oscimg,g.aggregated_rect)
		end
		osctemp= vgs.size-vgs.select{|x|x.matched}.size;
		osc+= osctemp
		## FP draw
		oscimg.write(File.join(des,"fp",k).to_s) if osctemp>0
	rescue Exception => e
		puts e
	end
end

truth_dat.each{|k,v| cso+=v.size if !cv_processed.include? k}
puts "True Positive: #{inter}"
puts "True Positive Distance: #{inter_c}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"

