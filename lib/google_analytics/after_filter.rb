module GoogleAnalytics
  module AfterFilter
    class << self
      def included(base)
        base.class_eval do 
          after_filter :add_google_analytics
        end
      end
    end
    
    def add_google_analytics
      unless GoogleAnalytics.use_javascript_links
        response.body = GoogleAnalytics.add_urchin_trackers(response.body) 
      end
      GoogleAnalytics.enabled? ? append_javascript : append_disabled_warning
    end
    
    def append_javascript
      append_to_body GoogleAnalytics.javascript_snippet(request)
    end
    
    def append_disabled_warning
      append_to_body GoogleAnalytics.disabled_warning
    end
    
    def append_to_body(code)
      response.body.gsub! '</body>', code + '</body>' if response.content_type == "text/html"
    end
  end
end