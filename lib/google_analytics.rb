require 'rexml/xpath'

module GoogleAnalytics
  @@id = nil
  mattr_accessor :id

  @@url = 'http://www.google-analytics.com/urchin.js'
  mattr_accessor :url
  
  @@ssl_url = 'https://ssl.google-analytics.com/urchin.js'
  mattr_accessor :ssl_url

  @@environments = ['production']  
  mattr_accessor :environments

  # Specify a different domain name from the default, if you have several
  # subdomains that you want to combine into one report.  See the Google
  # Analytics documentation for more information.
  @@domain_name = nil
  mattr_accessor :domain_name 
  
  @@use_javascript_links = false
  mattr_accessor :use_javascript_links
  
  @@map_regexps = {}
  mattr_accessor :map_regexps
  
  class << self    
    def enabled?
      environment_included? and id_set?
    end
    
    def id_set?
      not id.blank?
    end
    
    def environment_included?
      environments.include?(RAILS_ENV)
    end
  
    def javascript_snippet(request)
      url = (not request.blank? and request.ssl?) ? ssl_url : self.url
      filename = File.join(File.dirname(__FILE__), "templates", "javascript_snippet.html.erb")
      javascript = File.open(filename) { |f| ERB.new(f.read) }
      javascript.result(binding)
    end
    
    def disabled_warning
      warning = []
      warning << "- You haven't specified your Google Analytics ID in your plugin settings." unless id_set?
      warning << "- Current environment is not included. You may change this in your plugin settings." unless environment_included?
      unless warning.empty?
        warning.unshift "Google Analytics integration is disabled for the following reasons:" 
        "<!-- \n" + warning.join("\n") + "\n-->\n"
      end
    end    
    
    def add_urchin_trackers(string)
      return string unless GoogleAnalytics.enabled?
      doc = REXML::Document.new(string)
      REXML::XPath.each(doc, "//a") do |node|
        string = parse_urchin_tracker(string, node)
      end
      string
    end
    
    def add_urchin_tracker(*args)
      link, token = *args
      return link unless GoogleAnalytics.enabled?
      node = REXML::Document.new(link).root
      parse_urchin_tracker(link, node, token)
    end
    
    def parse_urchin_tracker(string, node, token = nil)
      href, onclick = node.attributes['href'], node.attributes['onclick']
      if onclick.nil? && href
        onclick = apply_regexps(href)
        onclick = token ? token.sub('$1', onclick) : onclick    
        onclick.gsub!(/\/\//, '/')# guard against double slashes
        string.sub("href=\"#{href}\"", "href=\"#{href}\" onclick=\"urchinTracker('#{onclick}');\"")      
      else
        string
      end
    end
    
    def apply_regexps(href)
      map_regexps.each do |regexp, token|
        next unless matches = href.match(regexp)
        matches.to_a.each_with_index do |match, ix|
          href = token.sub!("$#{ix + 1}", match) if token =~ Regexp.new("\\$#{ix + 1}")
        end
      end
      href
    end
  end
end

unless ENV['RAILS_ENV'] == 'test'
  ActionController::Base.send(:include, GoogleAnalytics::AfterFilter) if defined?('ActionController')
  #Liquid::Template.register_filter(GoogleAnalytics::Filters)
  #FilteredColumn.macros[:google_analytics_macro] = GoogleAnalytics::Macro
end
