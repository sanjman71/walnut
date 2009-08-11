class SphinxJob < Struct.new(:params)

  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/sphinx.log")
    end
  end
  
  def perform
    logger.info "*** #{Time.now}: sphinx job: #{params.inspect}"

    case params[:index]
    when 'appointment', 'appointments', 'events'
      index = 'appointment_core'
    when 'location', 'locations'
      index = 'location_core'
    else
      if params[:index].match(/_core$/) || params[:index].match(/_delta$/)
        # use index name as is
        index = params[:index]
      else
        logger.error "#{Time.now}: xxx invalid index #{params[:index]}"
        return
      end
    end

    # rebuild index
    config = ThinkingSphinx::Configuration.instance
    client = Riddle::Client.new config.address, config.port
    output = `#{config.bin_path}indexer --config #{config.config_file} --rotate #{index}`
    logger.info output unless ThinkingSphinx.suppress_delta_output?
    
    true
  end
  
end