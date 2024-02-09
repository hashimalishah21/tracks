module Webrat
  class SeleniumSession < Session
    
    def initialize(selenium_driver)
      @selenium = selenium_driver
      define_location_strategies
    end
    
    def visits(url)
      @selenium.open(url)
    end
    
    def fills_in(label_text, options)
      @selenium.type("webrat=#{Regexp.escape(label_text)}", "#{options[:with]}")
    end
    
    def response_body
      @selenium.get_html_source
    end
    
    def clicks_button(button_text = nil)
      button_text ||= '*'
      @selenium.click("button=#{button_text}")
      @selenium.wait_for_page_to_load()
    end

    def clicks_link(link_text)
      @selenium.click("webratlink=#{Regexp.escape(link_text)}")
      @selenium.wait_for_page_to_load()
    end
    
    def selects(option_text, options = {})
      id_or_name_or_label = options[:from]
      
      if id_or_name_or_label
        select_locator = "webrat=#{id_or_name_or_label}"
      else
        select_locator = "webratselectwithoption=#{option_text}"
      end
      @selenium.select(select_locator, option_text)
    end
    
    def chooses(label_text)
      @selenium.click("webrat=#{label_text}")
    end
        
    def checks(label_text)
      @selenium.check("webrat=#{label_text}")
    end
        
    protected
        
    def define_location_strategies
      @selenium.add_location_strategy('label', <<-JS)
        var allLabels = inDocument.getElementsByTagName("label");
        var candidateLabels = $A(allLabels).select(function(candidateLabel){
          var regExp = new RegExp('^' + locator + '\\\\b', 'i');
          var labelText = getText(candidateLabel).strip();
          return (labelText.search(regExp) >= 0);
        });
        if (candidateLabels.length == 0) {
          return null;      
        }
        candidateLabels = candidateLabels.sortBy(function(s) { return s.length * -1; }); //reverse length sort
        var locatedLabel = candidateLabels.first();
        var labelFor = locatedLabel.getAttribute('for');
        return selenium.browserbot.locationStrategies['id'].call(this, labelFor, inDocument, inWindow);
      JS

      @selenium.add_location_strategy('webrat', <<-JS)
        var locationStrategies = selenium.browserbot.locationStrategies;
        return locationStrategies['id'].call(this, locator, inDocument, inWindow)
                || locationStrategies['name'].call(this, locator, inDocument, inWindow)
                || locationStrategies['label'].call(this, locator, inDocument, inWindow)
                || null;
      JS

      @selenium.add_location_strategy('button', <<-JS)
        if (locator == '*') {
          return selenium.browserbot.locationStrategies['xpath'].call(this, "//input[@type='submit']", inDocument, inWindow)
        }
        var inputs = inDocument.getElementsByTagName('input');
        return $A(inputs).find(function(candidate){
          inputType = candidate.getAttribute('type');
          if (inputType == 'submit' || inputType == 'image') {
            var buttonText = $F(candidate);
            return (PatternMatcher.matches(locator + '*', buttonText));
          }
          return false;
        });
      JS
      
      @selenium.add_location_strategy('webratlink', <<-JS)
        var links = inDocument.getElementsByTagName('a');
        var candidateLinks = $A(links).select(function(candidateLink) {
          return PatternMatcher.matches(locator, getText(candidateLink));
        });
        if (candidateLinks.length == 0) {
          return null;
        }
        candidateLinks = candidateLinks.sortBy(function(s) { return s.length * -1; }); //reverse length sort
        return candidateLinks.first();
      JS
      
      @selenium.add_location_strategy('webratselectwithoption', <<-JS)
        var optionElements = inDocument.getElementsByTagName('option');
        var locatedOption = $A(optionElements).find(function(candidate){
          return (PatternMatcher.matches(locator, getText(candidate)));
        });
        return locatedOption ? locatedOption.parentNode : null;
      JS
    end
    
  end
end