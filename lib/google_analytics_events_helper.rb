module GoogleAnalyticsEventsHelper
  
  def track_home_ga_event(controller, action)
    @ga_events ||= []
    
    case controller
    when 'home'
      @ga_events.push("pageTracker._trackEvent('#{controller.titleize}', '#{action}');")
    end
  end
  
  def track_where_ga_event(controller, localities)
    @ga_events ||= []

    # use controller as category, and locality as action
    
    case controller
    when 'places', 'locations', 'events', 'search'
      Array(localities).compact.each do |locality|
        @ga_events.push("pageTracker._trackEvent('#{controller.titleize}', '#{locality.class.to_s}', '#{locality.name}');")
      end
    else
    end
  end
  
  def track_what_ga_event(controller, options)
    @ga_events ||= []

    # use controller as category, and tag or query as action
    if !options[:tag].blank?
      action  = 'Tag'
      label   = options[:tag]
    elsif !options[:query].blank?
      action  = 'Query'
      label   = options[:query]
    else
      # whoops, no action
      return
    end
    
    case controller
    when 'places', 'locations', 'events', 'search'
      @ga_events.push("pageTracker._trackEvent('#{controller.titleize}', '#{action}', '#{label}');")
    end
  end
  
  def track_chain_ga_event(controller, chain, locality=nil)
    @ga_events ||= []
    
    action = chain.is_a?(Chain) ? chain.name : chain.to_s
    label  = locality.name unless locality.blank?
    
    case controller
    when 'chains'
      @ga_events.push("pageTracker._trackEvent('#{controller.titleize}', '#{action}', '#{label}');")
    end
  end
  
end