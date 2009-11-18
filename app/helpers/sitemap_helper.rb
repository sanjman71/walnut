module SitemapHelper
  
  def sitemap_events_list
    [['Atlanta', '/events/us/ga/atlanta/q/anything'],
     ['Brooklyn', '/events/us/ny/brooklyn/q/anything'],
     ['Charlotte', '/events/us/nc/charlotte/q/anything'],
     ['Chicago', '/events/us/il/chicago/q/anything'],
     ['New York', '/events/us/ny/new-york/q/anything'],
     ['Philadelphia', '/events/us/pa/philadelphia/q/anything'],
     ['Pittsburgh', '/events/us/pa/pittsburgh/q/anything']
    ]
  end

  def sitemap_cities_list
    [['Atlanta', '/search/us/ga/atlanta/q/anything'],
     ['Brooklyn', '/search/us/ny/brooklyn/q/anything'],
     ['Charlotte', '/search/us/nc/charlotte/q/anything'],
     ['Chicago', '/search/us/il/chicago/q/anything'],
     ['New York', '/search/us/ny/new-york/q/anything'],
     ['Philadelphia', '/search/us/pa/philadelphia/q/anything'],
     ['Pittsburgh', '/search/us/pa/pittsburgh/q/anything']
    ]
  end

  def sitemap_neighborhoods_list
    [['River North', '/search/us/il/chicago/n/river-north/q/anything'],
     ['Manhattan', '/search/us/ny/new-york/n/manhattan/q/anything'],
     ['Midtown', '/search/us/ny/new-york/n/midtown/q/anything']
    ]
  end
  
  def sitemap_chains_list
    [['Dollar Tree', '/chains/us/310-dollar-tree'],
     ['McDonalds', '/chains/us/553-mcdonalds'],
     ['Wal Mart', '/chains/us/801-wal-mart'],
     ['Starbucks Coffee', '/chains/us/186-starbucks-coffee'],
     ['Target Stores', '/chains/us/1035-target-stores']
    ]
  end
end