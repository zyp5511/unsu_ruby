require 'set'
require 'rmagick'
require 'fileutils'
require_relative 'record'
require_relative 'transform_old'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: new_diff.rb [options]'
  opts.on('-s', '--source DIRNAME', 'Image Directory') do |v|
    options[:source] = v
  end

  opts.on('-a', '--annotation FILENAME', 'record file') do |v|
    options[:annotation] = v
  end

  opts.on('-p', '--predication FILENAME', 'head node list file') do |v|
    options[:predication] = v
  end

  opts.on('-t', '--threshold [VALUE]', Float, "threshold on annotation (I know it's wired)") do |v|
    options[:threshold] = v
  end

  opts.on('--annotheight [VALUE]', Float, 'threshold height lower bound') do |v|
    options[:annotheight] = v
  end

  opts.on('--predheight [VALUE]', Float, 'predication threshold height lower bound') do |v|
    options[:predheight] = v
  end

  opts.on('--th2 [VALUE]', Float, 'threshold of predication to be compared') do |v|
    options[:th2] = v
  end

  opts.on('-o', '--output FILENAME', 'output directory') do |v|
    options[:output] = v
  end

  opts.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
    options[:verbose] = v
  end

  opts.on('--info', 'Run extreme verbosely') do |_v|
    options[:info] = true
  end

  opts.on('--plot', 'Plot the result') do |v|
    options[:plot] = v
  end

  opts.on('--crop', 'Crop the result') do |v|
    options[:crop] = v
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

src = options[:source]
des = options[:output]
cvdat = options[:annotation]
lcdat = options[:predication]

# anntation filter
annot_records_raw = Record.seperate_records(src, IO.foreach(cvdat), Record.parsers[:cv])
if options.key?(:threshold)
  thres = options[:threshold]
  puts "annotation score threshold #{thres} is given"
  annot_records = Hash[annot_records_raw.map { |r| [r.filename, r.rects.select { |x| x.dis > thres }] }]
elsif options.key?(:annotheight)
  tt = options[:annotheight]
  puts "annotation height lower bound #{tt} is given"
  annot_records = Hash[annot_records_raw.map { |r| [r.filename, r.rects.select { |x| x.h > tt }] }]
else
  annot_records = Hash[annot_records_raw.map { |r| [r.filename, r.rects] }]
end

puts "start processing file:#{lcdat}"

# record filter
#
record_choosers = []
if options.key?(:th2)
  puts "predication score threshold #{options[:th2]} is given"
  record_choosers << ->(x) { x.dis > options[:th2] }
end

if options.key?(:predheight)
  puts "predication height threshold #{options[:predheight]} is given"
  record_choosers << ->(x) { x.h > options[:predheight] }
end

if !record_choosers.empty?
  pred_records = Hash[Record.seperate_records(src, IO.foreach(lcdat), Record.parsers[:cv]).map { |r| [r.filename, r.rects.select { |x| record_choosers.all? { |y| y.call(x) } }] }]
else
  pred_records = Hash[Record.seperate_records(src, IO.foreach(lcdat), Record.parsers[:cv]).map { |r| [r.filename, r.rects] }]
end

puts "there are #{pred_records.length} records" if options.key?(:info)

# Created needed folders.
FileUtils.mkdir(des) unless File.directory?(des)

fndir = File.join(des, 'fn')
FileUtils.mkdir(fndir) unless File.directory?(fndir)

tpdir = File.join(des, 'tp')
FileUtils.mkdir(tpdir) unless File.directory?(tpdir)

fpdir = File.join(des, 'fp')
FileUtils.mkdir(fpdir) unless File.directory?(fpdir)

def draw_rect(ori, cvr)
  rdraw = Magick::Draw.new
  rdraw.stroke('yellow').stroke_width(0.5)
  rdraw.fill('transparent')
  rdraw.rectangle(cvr.x, cvr.y, cvr.x + cvr.w - 1, cvr.y + cvr.h - 1)
  # rdraw.text(cvr.x+1,cvr.y+cvr.h-20,cvr.type.to_s)
  rdraw.text(cvr.x + 1, cvr.y + 1, cvr.type.to_s.inspect) unless cvr.type.nil?
  rdraw.text(cvr.x + 1, cvr.y + cvr.h - 20, cvr.dis.to_s.inspect) unless cvr.dis.nil?
  rdraw.draw(ori)
rescue StandardError => e
  puts 'draw_rect=======================Error!====================='
  puts cvr.inspect
  puts e.backtrace.join("\n")
  puts 'process_rect=======================Error!====================='
end

def crop_rect(ori, rect, subdir, filename)
  temp = ori.crop(rect.x, rect.y, rect.w, rect.h, true)
  # type = rect.type
  temp.write("#{File.join(subdir, File.basename(filename, File.extname(filename)))}_#{rect.x}+#{rect.y}+#{rect.w}x#{rect.h}#{File.extname(filename)}")
end

def compare_annot_vs_pred(annot_rec, pred_rec)
  num_fp = 0 # fp
  num_fn = 0 # fn
  num_tp = 0 # tp
  matched_rects = Set.new
  matched_annot = Set.new
  missed_annot = Set.new
  annot_rec.each do |annot_rect|
    current_matched_rects = pred_rec.select { |vr| vr.has_point annot_rect.x + (annot_rect.w / 2), annot_rect.y + (annot_rect.h / 2) }
    if current_matched_rects.empty?
      # miss found
      num_fn += 1
      missed_annot.add(annot_rect)
    else
      # matched
      num_tp += 1
      matched_annot.add(annot_rect)
      matched_rects.merge(current_matched_rects)
    end
  end
  [num_tp, num_fn, num_fp, matched_rects, matched_annot, missed_annot]
end

fnrect = []
fprect = []
tprect = []

annot_processed = Set.new

res = pred_records.map do |k, v|
  matched_rects = Set.new # Matched rects out of v
  if options.key?(:plot) || options.key?(:crop)
    fn_img = Magick::Image.read(File.join(src, k).to_s).first
    fp_img =  fn_img.clone
    tp_img =  fn_img.clone
  end

  fnrect << k
  tprect << k
  fprect << k
  num_tp = 0
  num_fn = 0
  num_fp = 0
  if !annot_records[k].nil?
    annot_processed << k
    num_tp, num_fn, num_fp, matched_rects, matched_annot, missed_annot =
      compare_annot_vs_pred(annot_records[k], v)
    matched_rects.each { |r| tprect << r }
    missed_annot.each { |r| fnrect << r }
    if matched_rects.length > 1
      puts "multiple matches in #{k}" if options.key?(:info)
    end
    if options.key?(:plot)
      if num_fn > 0
        # Plot missing faces
        missed_annot.each { |g| draw_rect(fn_img, g) }
        fn_img.write(File.join(des, 'fn', k).to_s)
      end
      if num_tp > 0
        # Plot dectected faces
        matched_annot.each { |g| draw_rect(tp_img, g) }
        matched_rects.each { |g| draw_rect(tp_img, g) }
        tp_img.write(File.join(des, 'tp', k).to_s)
      end
    elsif options.key?(:crop)
      matched_rects.each { |g| crop_rect(tp_img, g, tpdir, k) }
    end

  else
    puts "postive annotation not found for image #{k}" if options.key?(:info)
  end
  v.reject { |x| matched_rects.include?(x) }.each do |g|
    # Export false alert
    fprect << g
    if options.key?(:plot)
      draw_rect(fp_img, g)
    elsif options.key?(:crop)
      crop_rect(fp_img, g, fpdir, k)
    end
  end
  osctemp = v.length - matched_rects.length
  num_fp += osctemp
  ## plot FP count
  if options.key?(:plot)
    rdraw = Magick::Draw.new
    rdraw.stroke('yellow').stroke_width(1)
    rdraw.text(16, 16, osctemp.to_s.inspect)
    rdraw.draw(fp_img)
    ## FP draw
    fp_img.write(File.join(des, 'fp', k).to_s) if osctemp > 0
  end

  ## remove empty records
  fnrect.pop if fnrect[-1] == k
  tprect.pop if tprect[-1] == k
  fprect.pop if fprect[-1] == k
  [num_tp, num_fp, num_fn]
end

res = res.transpose
inter = res[0].sum
osc = res[1].sum
cso = res[2].sum

## images on which no positive is detected
cso_extra = 0
annot_records.each do |k, v|
  next if annot_processed.include? k
  cso_extra += v.length
  next if v.empty?
  fnrect << k
  fn_img = Magick::Image.read(File.join(src, k).to_s).first
  annot_records[k].each { |cvr| fnrect << k; draw_rect(fn_img, cvr) }
  fn_img.write(File.join(des, 'fn', k).to_s)
end

def output_stat(fn, rects)
  ct = 0
  File.open(fn, 'w') do |f|
    rects.each do |r|
      if r.instance_of?(Rect)
        f.puts r.to_s
        ct += 1
      else
        f.puts ct
        f.puts r
        ct = 0
      end
    end
  end
end

# Export per-viewlet histogram.
if !options[:verbose].nil? && options[:verbose]
  puts 'outputing in verbose mode'
  output_stat(File.join(des, 'fnstat.txt'), fnrect)
  output_stat(File.join(des, 'tpstat.txt'), tprect)
  output_stat(File.join(des, 'fpstat.txt'), fprect)
end

cso += cso_extra
puts "True Positive: #{inter}"
puts "Missing: #{cso}"
puts "False Positive: #{osc}"
puts "Extra missing #{cso_extra}"
puts '-' * 25

3.times { puts }
