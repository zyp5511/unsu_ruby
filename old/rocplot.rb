# create data list for gnuplot use
require 'set'
require 'RMagick'
require 'fileutils'
require_relative 'record'

cvdat = ARGV[0]
lcdat = ARGV[1]
headdat = ARGV[2]
transfn = ARGV[3]
netfn = ARGV[4]
elfn = ARGV[5]

nettable = LCTransformFullTable.loadTable(netfn) # hard coded cluster number, should be changed later
nettable.restrict elfn

table = LCTransformTable.loadMap(transfn, 1006) # hard coded cluster number, should be changed later
orihead = IO.readlines(headdat).map(&:to_i)
len = orihead.length

def parse_cv_data(fname)
  IO.foreach(fname).map(&:chomp).chunk { |l| l.end_with?('gif', 'jpg', 'png', 'jpeg') }.each_slice(2).map do |a|
    [a[0][1][0], a[1][1].map { |x| Rect.makePureRect(x) }]
  end
end

cvrecords = Hash[parse_cv_data cvdat]
orilcrecords = Record.seperate_records(nil, nil, IO.foreach(lcdat)).reject { |r| r.rects.nil? }

total = 3306.0

(1..len).each do |l|
  cso = 0
  osc = 0
  inter = 0
  head = orihead.take(l).to_set
  lcrecords = Hash[orilcrecords.each { |r| r.pick_good_set head; r.group_rects table }.reject { |r| r.groups.values.to_set.empty? }.map { |r| [r.filename, r] }]
  cv_processed = Set.new
  lcrecords.each do |k, v|
    # ori = Magick::Image.read(File.join(src,k).to_s).first
    # oscimg =  ori.clone

    v.groups.values.to_set.each(&:aggregate)
    # vg = v.groups.values.to_set
    vg = v.groups.values.to_set.select { |y| y.rects.length > 1 }

    unless cvrecords[k].nil?
      cv_processed << k
      found = false
      cvrecords[k].each do |cvr|
        vid = vg.select { |vr| vr.aggregated_rect.has_point cvr.x + (cvr.w / 2), cvr.y + (cvr.h / 2) }
        if vid.empty?
          # miss found
          cso += 1
          found = true
        else
          vid.each { |g| g.matched = true; }
          inter += 1
        end
      end
      if found
      end
    end
    found = false
    osc += vg.size - vg.select(&:matched).size
  end

  cvrecords.each { |k, v| cso += v.size unless cv_processed.include? k }
  puts "#{inter / total}\t#{osc}"
end
