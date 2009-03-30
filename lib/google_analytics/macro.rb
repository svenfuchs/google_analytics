module GoogleAnalytics
  class Macro < FilteredColumn::Macros::Base
    def self.filter(attributes, link = '', text = '')
      GoogleAnalytics.add_urchin_tracker(link, attributes[:token])
    end
  end
end