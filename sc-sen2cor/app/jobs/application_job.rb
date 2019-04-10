class ApplicationJob < ActiveJob::Base
	require "cgi"
	queue_as :default
 
	def perform(rid)
		@ap = AsyncProcess.find_by_rid(rid)
		if !@ap.nil?
			@ap.update_attributes(status: 1)

			level1dir = CGI::parse(@ap.request)["level1dir"].first rescue nil
			resolution = CGI::parse(@ap.request)["resolution"].first.to_i rescue nil

			if level1dir.nil? or resolution.nil?
				@ap.update_attributes(status: -2)
			else
				l1dirs = Dir.glob("/data/" + level1dir + "/*/S2?_MSIL1C_*.SAFE")
				success = true
				for l1dir in l1dirs
					cmd = "../../Sen2Cor-02.05.05-Linux64/bin/L2A_Process --resolution " + resolution.to_s + " " + l1dir
					if !system(cmd)
						success = false
						break
					end
				end
				if success
					generateHash = "cd /data/" + level1dir.to_s + " && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | head -c 64"
					retVal = `#{generateHash}`
					@ap.update_attributes(status: 2, file_hash: retVal.to_s)
				else
					@ap.update_attributes(status: -1)
				end
			end
		end

	end
end
