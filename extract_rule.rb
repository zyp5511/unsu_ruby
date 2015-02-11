require_relative 'transform'

src = ARGV[0]

tc = LCTransformSet.loadAll(src)
tc.simplify(:avg,594).each{|x| puts x}
