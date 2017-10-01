# finding the responding clusters on missing faces in a given list of hard examples.
require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

src = ARGV[0]
$des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]
hardfn = ARGV[4]

hard = IO.readlines(hardfn).map(&:chomp).to_set

def parse_cv_data(fname)
  IO.foreach(fname).map(&:chomp).chunk { |l| l.end_with?('jpg', 'png') }.each_slice(2).map do |a|
    [a[0][1][0], a[1][1].map { |x| Rect.makePureRect(x) }]
  end
end

def crop_rect(ori, filename, rect)
  temp = ori.crop(rect.x, rect.y, rect.w, rect.h, true)
  type = rect.type
  subdir = "#{$des}/#{type}".chomp
  FileUtils.mkdir(subdir) unless File.directory?(subdir)
  temp.write("#{File.join(subdir, File.basename(filename, File.extname(filename)))}_#{rect.x}+#{rect.y}+#{rect.w}x#{rect.h}_#{type}#{File.extname(filename)}")
end

# lcrecords = Hash[Record::seperate_records(src,des,IO.foreach(report)).map{|r|[r.filename, r.rects.map{|r| table.tranform(r)]}}]
cvrecords = Hash[parse_cv_data cvdat]
lcrecords = Hash[Record.seperate_records(src, $des, IO.foreach(lcdat)).select { |r| hard.include? r.filename }.map { |r| [r.filename, r.rects] }]

puts "There are #{lcrecords.length} in hard samples"

fcount = 0

lcrecords.each do |k, v|
  ori = Magick::Image.read(File.join(src, k).to_s).first
  oscimg = ori.clone
  if !cvrecords[k].nil?
    found = false
    cvrecords[k].each do |cvr|
      vid = v.select { |vr| vr.has_point cvr.x + (cvr.w / 2), cvr.y + (cvr.h / 2) }
      fcount += vid.length
      vid.each do |r|
        crop_rect ori, k, r
      end
    end
  else
    puts "CV records not found for #{k}"
  end
end
