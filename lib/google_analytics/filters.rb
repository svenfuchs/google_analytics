module GoogleAnalytics    
  module Filters    
    def google_analytics(*args)
      GoogleAnalytics.add_urchin_tracker(*args)
    end
  end
end