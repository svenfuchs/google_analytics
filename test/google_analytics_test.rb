require 'vendor/rails/activesupport/lib/active_support/core_ext/blank.rb'
require 'vendor/rails/activesupport/lib/active_support/core_ext/array/extract_options.rb'
Array.send :include, ActiveSupport::CoreExtensions::Array::ExtractOptions
require 'vendor/rails/activesupport/lib/active_support/core_ext/module/attribute_accessors.rb'
require 'rexml/document'
require 'test/unit' 

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
ENV['RAILS_ENV'] ||= 'test'
RAILS_ENV = ENV['RAILS_ENV']

require File.dirname(__FILE__) + '/../init.rb'

class GoogleAnalyticsTest < Test::Unit::TestCase 
  def setup 
    enable
    @link = '<a href="/path/to/filename.txt"></a>'
    @no_href_link = '<a name="some_name"></a>'
    @onclick_link = '<a href="/path/to/filename.txt" onclick="something"></a>'
    GoogleAnalytics.map_regexps = {}
  end
  
  def enable
    set_id
    include_environment
  end
  
  def disable
    unset_id
  end
  
  def set_id
    GoogleAnalytics.id = 'UA-12345-67'
  end
  
  def unset_id
    GoogleAnalytics.id = nil
  end
  
  def include_environment
    GoogleAnalytics.environments << 'test'
  end
  
  def uninclude_environment
    GoogleAnalytics.environments = []
  end
  
  def assert_urchin(expect, *args)
    assert_match Regexp.new(Regexp.escape(expect)), GoogleAnalytics.add_urchin_tracker(*args)
  end
  
  def test_with_id_set_and_env_included_IT_should_be_enabled
    set_id
    include_environment
    assert GoogleAnalytics.enabled?
  end
  
  def test_with_no_id_set_IT_should_be_disabled
    unset_id
    assert !GoogleAnalytics.enabled?
  end
  
  def test_with_env_not_included_IT_should_be_disabled
    uninclude_environment
    assert !GoogleAnalytics.enabled?
  end
  
  def test_with_plugin_not_enabled_nothing_links_should_not_be_modified
    disable
    assert_equal @link, GoogleAnalytics.add_urchin_tracker(@link, 'sometoken/$1')
  end
  
  def test_with_a_link_with_no_href_IT_should_not_modify_the_link
    assert_equal @no_href_link, GoogleAnalytics.add_urchin_tracker(@no_href_link, 'sometoken/$1')
  end
  
  def test_with_a_link_with_an_onclick_IT_should_not_modify_the_link
    assert_equal @onclick_link, GoogleAnalytics.add_urchin_tracker(@onclick_link, 'sometoken/$1')
  end
  
  def test_with_no_token_and_no_map_defined_IT_should_use_the_unmodified_path
    assert_urchin "urchinTracker('/path/to/filename.txt');", @link
  end
  
  def test_with_a_token_and_no_map_defined_IT_should_inject_the_path_into_the_token
    assert_urchin "urchinTracker('leading/path/to/filename.txt/trailing')", @link, "leading/$1/trailing"
  end
  
  def test_with_no_token_and_a_regexp_map_defined_IT_should_inject_the_regexp_match_into_the_token_from_the_map
    GoogleAnalytics.map_regexps = { /^.*(doc|pdf|txt)$/ => 'documents/$1' }    
    assert_urchin "urchinTracker('documents/path/to/filename.txt')", @link
    
    GoogleAnalytics.map_regexps = { /[^.\/]*\.(doc|pdf|txt)$/ => 'documents/$1' }    
    assert_urchin "urchinTracker('documents/filename.txt')", @link
    
    GoogleAnalytics.map_regexps = { /[^.\/]*\.(doc|pdf|txt)$/ => 'documents/$2/$1' }    
    assert_urchin "urchinTracker('documents/txt/filename.txt')", @link
  end
  
  def test_with_a_token_and_a_regexp_map_defined_IT_should_combine_both_of_them
    GoogleAnalytics.map_regexps = { /[^.\/]*\.(doc|pdf|txt)$/ => 'documents/$2/$1' }
    assert_urchin "urchinTracker('documents/txt/filename.txt/trailing')", @link, '$1/trailing'
  end
  
  def test_with_a_bunch_of_links_IT_should_work_on_them_accordingly
    html = '<html>' + @link + @no_href_link + @onclick_link + '</html>'
    ["urchinTracker('/path/to/filename.txt');", @no_href_link, @onclick_link].each do |expect|
      assert_match Regexp.new(Regexp.escape(expect)), GoogleAnalytics.add_urchin_trackers(html)
    end
  end
end







