require_relative 'record'
require_relative 'network'
require_relative 'voro_table'
require 'set'

oper = ARGV[0]
src = ARGV[1]
des = ARGV[2]
report = ARGV[3]

if !File.directory?(des)
	FileUtils.mkdir(des)
end

records = Record::seperate_records(src,IO.foreach(report),Record::parsers[:cv])
puts "there are #{records.length} records"

if oper == "list"
	process = lambda do |x|
		puts x.filename;
	end
elsif oper == "draw"
	process = lambda do |x|
		x.rects.each do |r|
			begin
				#x.draw_rect(r,"\#ffffff") if r.dis > 3.6
				x.draw_rect(r,"\#ffffff")
			rescue Exception => e
				puts "process_rect=======================Error!====================="
				puts e.backtrace.join("\n")
				puts "process_rect=======================Error!====================="
			end
		end
		x.export des
	end
end

c=0
records.each do|x|
	begin
		if !x.rects.empty?
			c+=1
			process.call(x)
		end
	rescue Exception => e
		puts "process_rect=======================Error!====================="
		puts e.backtrace.join("\n")
		puts "process_rect=======================Error!====================="
	end
end

puts " #{c} images processed"
