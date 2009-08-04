class SphinxJob < Struct.new(:params)
  
  def perform
    puts("*** sphinx job params: #{params.inspect}")

    case params[:index]
    when 'appointments', 'events'
      index  = 'appointment_core'
    else
      puts "#{Time.now}: xxx invalid index #{params[:index]}"
    end

    # rebuild index
    config = ThinkingSphinx::Configuration.instance
    client = Riddle::Client.new config.address, config.port
    output = `#{config.bin_path}indexer --config #{config.config_file} --rotate #{index}`
    puts output unless ThinkingSphinx.suppress_delta_output?
    
    true
  end
  
end