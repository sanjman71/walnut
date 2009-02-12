module Ppds # :nodoc:

  class DoodleAdStub

    cattr_accessor :client_id, :language, :ad_channel,
                   :alternative_ad_url, :cpa_choice,
                   :color_border, :color_bg, :color_link,
                   :color_text, :color_url, :ui_features

  end

  module DoodleAdStubHelper

    FORMATS = {
      "text" => [
        [120, 240], [120, 600], [125, 125], [160, 600], [180, 150], [200, 200],
        [234,  60], [250, 250], [300, 250], [336, 280], [468,  60], [728,  90]
      ],
      "text_image" => [
        [120, 240], [120, 600], [125, 125], [160, 600], [180, 150], [200, 200],
        [234,  60], [250, 250], [300, 250], [336, 280], [468,  60], [728,  90]
      ],
      "image" => [
        [120, 600], [160, 600], [200, 200], [250, 250], [300, 250], [336, 280],
        [468,  60], [728,  90]
      ],
      "video" => [
        [120, 600], [160, 600], [200, 200], [250, 250], [300, 250], [336, 280],
        [468,  60], [728,  90]
      ],
      "links" => [
        [120,  90], [160,  90], [180,  90], [200,  90], [468,  15], [728,  15]
      ],
      "links5" => [
        [120,  90], [160,  90], [180,  90], [200,  90], [468,  15], [728,  15]
      ],
      "button" => [
        [110,  32], [120, 240], [120,  60], [125, 125], [180,  60], [468,  60]
      ]
    }.freeze
    
    TYPES = ["text", "image", "text_image"]
    
    def in_production?
      (RAILS_ENV == 'production' and not DoodleAdStub.client_id.blank?)
    end

    def sanitize_type(ad_type)
      FORMATS.keys.include?(ad_type.to_s) ? ad_type.to_s : "text"
    end

    def valid_format?
      FORMATS.fetch(@ad_type.to_s).include?([@ad_width, @ad_height])
    end

    def determine_format
      return false unless valid_format?
      return "#{@ad_width}x#{@ad_height}_0ads_al" if @ad_type.eql?("links")
      return "#{@ad_width}x#{@ad_height}_0ads_al_s" if @ad_type.eql?("links5")
      return "#{@ad_width}x#{@ad_height}_as"
    end

    def stub_image
      image = "#{@ad_width}x#{@ad_height}_#{@ad_type}.png"
      image_url = "/images/doodle_ad_stub/#{image}"
      image_path = File.join(RAILS_ROOT, "public", image_url)
      return "Stub image #{image} not found!" unless File.exists?(image_path)
      "<img src=\"#{image_url}\" alt=\"#{image}\" />"
    end

    def js_code
      return stub_image unless in_production?
      g = DoodleAdStub.new
      js = "<script type=\"text/javascript\">\n"
      js << "//<![CDATA[\n"
      js << "google_ad_client = '#{g.client_id}';\n"
      js << "google_ad_width = #{@ad_width};\n"
      js << "google_ad_height = #{@ad_height};\n"
      js << "google_ad_type = '#{@ad_type}';\n" if TYPES.include?(@ad_type)
      js << "google_ad_format = '#{@ad_format}';\n"
      js << "google_language = '#{g.language}';\n" unless g.language.nil?
      js << "google_cpa_choice = '#{g.cpa_choice}';\n" unless g.cpa_choice.nil?
      js << "google_color_border = '#{g.color_border}';\n" unless g.color_border.nil?
      js << "google_color_bg = '#{g.color_bg}';\n" unless g.color_bg.nil?
      js << "google_color_link = '#{g.color_link}';\n" unless g.color_link.nil?
      js << "google_color_url = '#{g.color_url}';\n" unless g.color_url.nil?
      js << "google_color_text = '#{g.color_text}';\n" unless g.color_text.nil?
      js << "google_alternative_ad_url = '#{g.alternative_ad_url}';\n" unless g.alternative_ad_url.nil?
      js << "google_ui_features  = '#{g.ui_features}';\n" if @ad_type.eql?("text") unless g.ui_features.nil? 
      js << "//]]>\n"
      js << "</script>\n"
      js << "<script src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\" type=\"text/javascript\"></script>\n"
      js
    end

    def google_ad(ad_width, ad_height, *ad_type)
      @ad_width  = ad_width
      @ad_height = ad_height
      @ad_type   = sanitize_type(ad_type)
      @ad_format = determine_format
      return "Invalid format #{@ad_width}x#{@ad_height} @ #{@ad_type}" unless @ad_format
      "<div class=\"google_adsense ad#{@ad_width}x#{@ad_height}\">\n" + js_code + "</div>\n"
    end

  end

end
