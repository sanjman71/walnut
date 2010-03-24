namespace :menu do

  namespace :allmenus do
    
    desc "Add menus for a city"
    task :import_city do
      city      = ENV["CITY"].to_s # e.g. chicago
      state     = ENV["STATE"].to_s # e.g. il
      isleep    = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 3
      limit     = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 10

      if city.blank? or state.blank?
        puts "[error] missing city or state"
        exit
      end

      state     = State.find_by_code(state.titleize)
      city      = state.cities.find_by_name(city.titleize) if state

      if city.blank? or state.blank?
        puts "[error] missing city or state"
        exit
      end
      
      url       = "http://www.allmenus.com/#{state.code.downcase}/#{city.name.downcase}/view-all"
      agent     = WWW::Mechanize.new
      searched  = 0
      matched   = 0
      
      agent.get(url)
      
      # search for cuisine urls
      urls = agent.page.search("div#content_left div#location_view_all_left ul li a").inject([]) do |array, a|
        href = a['href']
        # make sure its a real cuisine, e.g. it ends with /bagel/ and not /-/
        if href.match(/\/\w+\/$/)
          abs_path  = root_url(url) + href
          puts "*** url: #{abs_path}"
          array.push(abs_path)
        end
        array
      end

      puts "[ok] found #{urls.size} cuisines for #{city.name}:#{state.code}"

      urls.each do |cuisine_url|
        menu_urls = get_cuisine_menus(agent, cuisine_url)
        menu_urls.each do |menu_url|
          searched += 1
          location = import_menu(agent, menu_url)
          matched  += 1 if location
          sleep(isleep)
        end
      end

      puts "#{Time.now}: [completed] #{searched} searched, #{matched} matched"
    end

    desc "Add cuisine menus"
    task :import_cuisine do
      url       = ENV["URL"]
      isleep    = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 3
      agent     = WWW::Mechanize.new

      searched  = 0
      matched   = 0

      menu_urls = get_cuisine_menus(agent, url)
      menu_urls.each do |menu_url|
        searched += 1
        location = import_menu(agent, menu_url)
        matched  += 1 if location
        sleep(isleep)
      end

      puts "#{Time.now}: [completed]"
    end
    
    desc "Add menu"
    task :import_menu do
      url   = ENV["URL"]
      agent = WWW::Mechanize.new

      if url.blank?
        puts "[error] missing url"
        exit
      end

      location = import_menu(agent, url)

      puts "#{Time.now}: [completed]"
    end

    # desc "Add menu links from allmenus.com"
    # task :import_from_allmenus do
    #   start_url = ENV["URL"] ? ENV["URL"] : "http://www.allmenus.com/il/chicago/"
    #   isleep    = ENV["SLEEP"] ? ENV["SLEEP"].to_i : 3
    #   limit     = ENV["LIMIT"] ? ENV["LIMIT"].to_i : 10
    #   menu_urls = []
    # 
    #   agent     = WWW::Mechanize.new
    #   searched  = 0
    #   matched   = 0
    # 
    #   # get start page
    #   agent.get(start_url)
    # 
    #   # search for top restaurant links
    #   agent.page.search("div#location_left_online ul li").children.each do |menu_link|
    #     href = menu_link['href']
    #     next unless href.match(/\/menu\/$/)
    #     url  = root_url(start_url) + href
    #     puts "*** url: #{url}"
    #     menu_urls.push(url)
    #   end
    # 
    #   # search for restaurant search results
    #   agent.page.search("div#std_results div.result div.result_restaurant").xpath("h6/a[@href]").each do |menu_link|
    #     href = menu_link['href']
    #     next unless href.match(/\/menu\/$/)
    #     url  = root_url(start_url) + href
    #     puts "*** url: #{url}"
    #     menu_urls.push(url)
    #   end
    # 
    #   puts "#{Time.now}: [completed] #{searched} searched, #{matched} matched"
    # end

  end # allmenus
  
  # get all menus for a specific cuisine
  # e.g. http://www.allmenus.com/il/chicago/-/bagels/
  def get_cuisine_menus(agent, url)
    puts "*** getting cuisine menus: #{url}"
    # get and parse url
    agent.get(url)

    # search for restaurant search results
    urls = agent.page.search("div#std_results div.result div.result_restaurant").xpath("h6/a[@href]").inject([]) do |array, a|
      href = a['href']
      if href.match(/\/menu\/$/)
        abs_path  = root_url(url) + href
        puts "*** url: #{abs_path}"
        array.push(abs_path)
      end
      array
    end

    urls
  end

  # skip certain *bad* menus
  # e.g. http://www.allmenus.com/md/chicago/185356-the-blue-agave-tequila-bar--restaurant/menu/ - causes a redirect loop
  def skip_menu?(url)
    ["http://www.allmenus.com/md/chicago/185356-the-blue-agave-tequila-bar--restaurant/menu/",
     "http://www.allmenus.com/nj/new-york/20247-le-bistro-deli/menu/"].include?(url)
  end

  # import menu
  # e.g. http://www.allmenus.com/il/chicago/272001-portillos-hot-dogs/menu/
  def import_menu(agent, url)
    # check if this is a valid url
    return nil if skip_menu?(url)
    
    puts "**** importing menu: #{url}"
    # get and parse url
    agent.get(url)

    # parse and map to a location
    location = parse_menu_geo(agent, url)

    if location
      add_menu(location, agent, url)
    end

    location
  end

  # map a url lik 'http://www.allmenus.com/il/chicago/-/bagels' to 'http://www.allmenus.com'
  def root_url(s)
    match = s.match(/(http:\/\/[\w.]*)\//)
    match ? match[1] : ''
  end

  def add_menu(location, agent, url)
    # check page for 'no_menu' div
    if agent.page.search("div#restaurantmenu").xpath("div[@id='no_menu']").size == 0
      # there is a menu
      puts "[ok] adding menu"
      location.company.tag_list.add('menu')
      location.preferences[:menu] = url
    else
      # no menu
    end
    
    # check page for reviews tab
    agent.page.search("div#restaurant_tabs div.tab").each do |tab|
      tab.xpath("a").each do |a|
        href = a['href']
        if href.match(/\/reviews\/$/)
          puts "[ok] adding reviews"
          # found a reviews tag, mark the location with the url's full path
          root_url = root_url(url) # e.g. http://www.allmenus.com
          location.preferences[:reviews] = root_url + href
        elsif href.match(/\/info\/$/)
        end
      end
    end

    # check page for cuisines
    agent.page.search("meta").xpath("//meta[@name='cuisines']").each do |element|
      tags = element['content'].split(",").map{ |s| s.strip.downcase }
      puts "[ok] adding tags #{tags.inspect}"
      location.tag_list.add(tags)
    end

    # check page for order online
    agent.page.search("meta").xpath("//meta[@name='features']").each do |element|
      features = element['content']
      if features.match(/order online/i)
        puts "[ok] adding order online"
        location.tag_list.add('order online')
        location.preferences[:order_online] = url
      end
    end

    # commit all changes
    location.save
  end
  
  def parse_menu_geo(agent, url, options={})
    # parse url for city and state
    match             = url.match(/http:\/\/www.allmenus.com\/(\w+)\/(\w+)/)
    state             = match[1]
    city              = match[2]
    
    # get location name and address
    name              = agent.page.at("div#restaurant_info h1").text().strip # e.g. Portillo's Hot Dogs
    address           = agent.page.at("div#restaurant_info address").text().match(/(.*\d{5,5})/)[1] # e.g 100 W Ontario St, CHICAGO, IL 60610
    phone_and_online  = agent.page.at("div#restaurant_heading_left div#phone").text().strip # e.g. (312) 587-8910  |  Order Online
    phone             = PhoneNumber.format(phone_and_online.split("|").first.strip)

    # puts "*** name and address: #{name}:#{address}"

    # find city and state
    city      = address.split(",")[1].strip.downcase # e.g. chicago
    state     = address.split(",")[2].strip.slice(0,2).downcase # e.g. il

    # find street
    hash      = StreetAddress.components(address.split(",")[0])
    street    = "#{hash[:housenumber]} #{hash[:streetname]}"

    # build object hash using name, street, city, state
    object    = Hash["name" => name, "key" => name, "address" => street, "city" => city, "state" => state, "phone" => phone]

    # map to a location
    locations = LocationFinder.match(object, :log => 1)

    if locations.empty?
      puts "[error] no location found"
      MENU_ERROR_LOGGER.debug("[error] #{url}")
      MENU_ERROR_LOGGER.debug("[error] #{object.inspect}")
      return nil
    elsif locations.size > 1
      puts "[error] #{locations.size} found"
      MENU_ERROR_LOGGER.debug("[error] #{url}")
      MENU_ERROR_LOGGER.debug("[error] #{object.inspect}")
      return nil
    end

    locations.first
  end 
  
end