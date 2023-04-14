# Murphy's Chunky Bacon generator
# Chunky Bacon by why the lucky stiff
def toss
	rand(2).zero?
end

class String
	def randomize_case
		split('').map do |c| toss ? c.upcase : c.downcase end.join
	end
end

module Chunky
	FONT_FAMILIES = %w(serif sans-serif cursive fantasy monospace)
	
	def self.rand_color
		'#%x' % rand(0x1_00_00_00)
	end
	
	def self.bacon n
		chunky_bacon = Array.new n do
			'<span style="position: fixed; top: %dpx; left: %dpx; color: %s; font-size: %d%%; font-weight: %d00; font-sytle: %s; font-family: %s;">%s</span>' % [
				rand(800) - 30,
				rand(1200) - 100,
				rand_color,
				rand(300) + 10,
				rand(9) + 1,
				toss ? 'italic' : 'normal',
				FONT_FAMILIES[rand(FONT_FAMILIES.size)],
				'Chunky Bacon'.randomize_case,
			]
		end.join "\n"

		<<-OUT
		<html>
		<body style="background-color: #{rand_color};">
#{chunky_bacon}
		</body>
		</html>
		OUT
	end
end

require 'webrick'
class ChunkBaconServlet < WEBrick::HTTPServlet::AbstractServlet
	def do_GET req, res
		q = req.path
		res.body =
			case q
			when nil, '/'
				Chunky.bacon 100
			when /favicon.ico$/
				''
			when /\/(\d+)/
				Chunky.bacon $1.to_i
			else
				'what?'
			end			
		res['Content-Type'] = 'text/html'
	end
end

# 203 = 0xCB for ChunkyBacon
s = WEBrick::HTTPServer.new :Port => 203

s.mount '/', ChunkBaconServlet

s.mount_proc '/comic' do |req, res|
	res.body = '<img src="http://www.poignantguide.net/ruby/i/the.foxes-4e.png" />'
	res['Content-Type'] = "text/html"
end

trap("INT") { s.shutdown }
s.start
#CB
