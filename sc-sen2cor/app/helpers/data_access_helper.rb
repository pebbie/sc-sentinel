module DataAccessHelper
    def getData(params)
    	require 'securerandom'

    	# check if request ID is present
    	if params["rid"].nil?
    		# check if request was sent before
    		request_string = request.query_string
    		level1dir = CGI::parse(request_string)["level1dir"].first rescue nil
    		resolution = CGI::parse(request_string)["resolution"].first.to_i rescue nil

			normalized_request = "resolution=" + resolution.to_s
			normalized_request += "&level1dir=" + level1dir

    		@ap = AsyncProcess.find_by_request(normalized_request)
    		if @ap.nil?
    			# write new entry to table
    			if params["fid"].nil?
    				rid = SecureRandom.uuid
    			else
    				rid = params["fid"].to_s
    			end
    			@ap = AsyncProcess.new(
    				request: normalized_request,
    				rid: rid,
    				status: 0) # status 0 - job initialized
    			@ap.save

    			# setup job
    			ApplicationJob.perform_later rid

    			# return Request ID
    			puts "returning: " + rid.to_s
				return [{ "rid": rid, "status": 0 }.to_json]
    		end
    		rid = @ap.rid
    		case @ap.status
    		when 1
    			# puts "job in progress"
    		when 2
    			# puts "job finished"
    			retVal = [{"type": "files", "directory": rid.to_s, "hash": @ap.file_hash.to_s}.to_json]
    			return retVal
    		when -1
    			# puts "stopped with error"
    			return [{"file": "error"}.to_json]
    		end
    	else
    		rid = params["rid"].to_s
    		@ap = AsyncProcess.find_by_rid(rid)
    		if @ap.nil?
    			return []
    		else
	    		case @ap.status
	    		when 1
	    			# puts "job in progress"
	    		when 2
	    			# puts "job finished"
	    			retVal = [{"type": "files", "directory": rid.to_s, "hash": @ap.file_hash.to_s}.to_json]
	    			return retVal
	    		when -1
	    			# puts "stopped with error"
	    			return [{"file": "error"}.to_json]
	    		end
    		end
    	end
		[{ "rid": rid, "status": @ap.status }.to_json]
    end
end