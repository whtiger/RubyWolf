require 'net/http'
require 'htmlentities'

class RubyWolf

	def initialize(query)
		@query = query
		getpods()
	end

	def listpods()
		if (@pods.nil?)
			return {}
		end
		return @pods.keys
	end

	def getpods()
		if (@pods.nil?)
			puts "Loading"
			host = Net::HTTP.start("www.wolframalpha.com")
			res = host.get("/input/?i="+URI::encode(@query))

			@server = res.body.match(/server = '(.*?)'/)[1].gsub(/http:\/\//, '')
			@s = res.body.match(/&s=(\d+)/)[1]

			@pods={}
			res.body.scan(/sPod.*?id=(.*?)&cap.*?', '\d+', '.*?', '', '', '(.*?)('|:)/).each{ |x|
				if (x[0].size)
					@pods[x[1]] = x[0]
				end
			}
			res.body.scan(/tempFileID", '(.*?)'.*?fier", '\\"(.*?)\\/m).each{ |x|
				if (x[0].size > 10)
					@pods[x[1]] = x[0]
				end
			}
			puts "Loaded"
		end

		return @pods
	end

	def loadpod(podId)
		if (!@pods[podId].nil?)
			host = Net::HTTP.start(@server)
			res = host.get(podquery(podId))
			out=[]
			out[0] = res.body.match(/stringified": "(.*?)"/)[1]
			out[1] = res.body.match(/mOutput": "(.*?)"/)[1]
			out[0] = HTMLEntities.decode_entities(out[0])
			out.map!{|x|
				x.gsub!(/\\n/, "   ")
				x.gsub(/\\'/, "'")
			}
			if (out[0].size==0)
				out[0] = res.body.match(/result_.*?src="(.*?s=\d+)/)[1]
			end
			return out
		end
		return nil
	end

	def getout()
		out = loadpod('Result') 
		out = loadpod('Input') if out.nil?
		return out
	end

	def podquery(podId)
		pod = @pods[podId]
		if (!pod.nil?)
			return "/input/pod.jsp?id=" + pod + "&s=" + @s.to_s;
		end
		return ""
	end

	def podurl(podId)
		return "http://" + @server + podquery(podId)
	end

end

