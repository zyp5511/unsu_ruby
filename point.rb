class Point
  attr_accessor :type, :x, :y, :s
  def initialize(type, x, y, s)
    @type = type
    @x = x
    @y = y
    @s = s
  end

  def self.makePoint(sdesc)
    words = sdesc.chomp.split
    Point.new(words[0].to_i, words[1].to_f, words[2].to_f, words[3].to_f)
  end

  def self.loadGlobal(fname)
    global_t = {}

    IO.foreach(fname) do |l|
      p = makePoint(l)
      global_t[p.type] = p
    end
    global_t
  end
end
