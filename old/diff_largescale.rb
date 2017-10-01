require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

src = ARGV[0]
des = ARGV[1]
cvdat = ARGV[2]
lcdat = ARGV[3]
headdat = ARGV[4]
transfn = ARGV[5]
falseposfn = ARGV[6]

table = LCTransformTable.loadMap(transfn, 1006) # hard coded cluster number, should be changed later
head = IO.readlines(headdat).map(&:to_i).to_set

def parse_cv_data(fname)
  IO.foreach(fname).map(&:chomp).chunk { |l| l.end_with?('gif', 'jpg', 'png', 'jpeg') }.each_slice(2).map do |a|
    [a[0][1][0], a[1][1].map { |x| Rect.makePureRect(x) }]
  end
end

cvrecords = Hash[parse_cv_data cvdat]
lcrecords = Hash[Record.seperate_records(src, des, IO.foreach(lcdat)).reject { |r| r.rects.nil? }.map { |r| [r.filename, r.rects.select { |x| head.include?(x.type) }] }]

cso = 0
osc = 0
inter = 0

tphist = Array.new(1006, 0) # hard coded cluster count
fphist = Array.new(1006, 0) # hard coded cluster count

FileUtils.mkdir(des) unless File.directory?(des)

fndir = File.join(des, 'fn')
FileUtils.mkdir(fndir) unless File.directory?(fndir)

fpdir = File.join(des, 'fp')
FileUtils.mkdir(fpdir) unless File.directory?(fpdir)

File.open(falseposfn, 'w') do |fpfn|
  lcrecords.each do |k, v|
    # ori = Magick::Image.read(File.join(src,k).to_s).first
    # oscimg = ori.clone
    vv = v.map { |orir| table.transform orir }
    unless cvrecords[k].nil?
      found = false
      cvrecords[k].each do |cvr|
        vid = vv.select { |vr| vr.has_point cvr.x + (cvr.w / 2), cvr.y + (cvr.h / 2) }
        if vid.empty?
          # miss found
          cso += 1
          found = true
        # rdraw = Magick::Draw.new
        # rdraw.stroke('yellow').stroke_width(0.5)
        # rdraw.fill("transparent")
        # rdraw.rectangle(cvr.x,cvr.y,cvr.x+cvr.w-1,cvr.y+cvr.h-1)
        # rdraw.draw(ori)
        else
          # matched
          vid.each { |x| x.matched = true }
          inter += 1
        end
      end
      if found
        # export missing faces
        # ori.write(File.join(des,'fn',k).to_s)
      end
    end
    found = false
    vv.select(&:matched).each { |vvr| tphist[vvr.type] += 1 }
    vv.reject(&:matched).each do |vvr|
      # export false alert
      fphist[vvr.type] += 1
      found = true
      fpfn.puts "#{k}\t#{vvr}"
      # vrdraw = Magick::Draw.new
      # vrdraw.stroke('red').stroke_width(0.5)
      # vrdraw.fill("transparent")
      # vrdraw.rectangle(vvr.x,vvr.y,vvr.x+vvr.w-1,vvr.y+vvr.h-1)
      # vrdraw.text(vvr.x+1,vvr.y+20,vvr.type.to_s)
      # vrdraw.draw(oscimg)
    end
    osc += vv.size - vv.select(&:matched).size
    # oscimg.write(File.join(des,"fp",k).to_s) if found
  end
end

File.open(File.join(des, 'tphist.txt'), 'w') do |f|
  tphist.each_with_index { |x, i| f.puts "#{i}\t#{x}" }
end
File.open(File.join(des, 'fphist.txt'), 'w') do |f|
  fphist.each_with_index { |x, i| f.puts "#{i}\t#{x}" }
end
puts "True Positive: #{inter}\tMissing: #{cso}\tFalse Positive: #{osc}"
