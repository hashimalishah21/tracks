# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # Convert a date object to the format specified
  # in config/settings.yml
  #
  def format_date(date)
    if date
      date_format = @user.preferences["date_format"]
      formatted_date = date.strftime("#{date_format}")
    else
      formatted_date = ''
    end
  end

  # Uses RedCloth to transform text using either Textile or Markdown
  # Need to require redcloth above
  # RedCloth 3.0 or greater is needed to use Markdown, otherwise it only handles Textile
  #
  def markdown(text)
    RedCloth.new(text).to_html
  end

  # Wraps object in HTML tags, tag
  #
  def tag_object(object, tag)
    tagged = "<#{tag}>#{object}</#{tag}>"
  end

  # Converts names to URL-friendly format by substituting underscores for spaces
  #
  def urlize(name)
      name.to_s.gsub(/ /, "_")
  end
  
  # Replicates the link_to method but also checks request.request_uri to find
  # current page. If that matches the url, the link is marked
  # id = "current"
  #
  def navigation_link(name, options = {}, html_options = nil, *parameters_for_method_reference)
    if html_options
      html_options = html_options.stringify_keys
      convert_options_to_javascript!(html_options)
      tag_options = tag_options(html_options)
    else
      tag_options = nil
    end
    url = options.is_a?(String) ? options : self.url_for(options, *parameters_for_method_reference)    
    id_tag = (request.request_uri == url) ? " id=\"current\"" : ""
    
    "<a href=\"#{url}\"#{tag_options}#{id_tag}>#{name || url}</a>"
  end
  
  # Check due date in comparison to today's date
  # Flag up date appropriately with a 'traffic light' colour code
  #
  def due_date(due)
    if due == nil
      return ""
    end

    @now = Date.today
    @days = due-@now
       
    case @days
      # overdue or due very soon! sound the alarm!
      when -1000..-1
        "<a title='" + format_date(due) + "'><span class=\"red\">Overdue by " + (@days * -1).to_s + " days</span></a> "
      when 0
           "<a title='" + format_date(due) + "'><span class=\"amber\">Due Today</span></a> "
      when 1
           "<a title='" + format_date(due) + "'><span class=\"amber\">Due Tomorrow</span></a> "
      # due 2-7 days away
      when 2..7
      if @user.preferences["due_style"] == "1"
        "<a title='" + format_date(due) + "'><span class=\"orange\">Due on " + due.strftime("%A") + "</span></a> "
      else
        "<a title='" + format_date(due) + "'><span class=\"orange\">Due in " + @days.to_s + " days</span></a> "
      end
      # more than a week away - relax
      else
        "<a title='" + format_date(due) + "'><span class=\"green\">Due in " + @days.to_s + " days</span></a> "
    end
  end

  # Check due date in comparison to today's date
  # Flag up date appropriately with a 'traffic light' colour code
  # Modified method for mobile screen
  #
  def due_date_mobile(due)
    if due == nil
      return ""
    end

    @now = Date.today
    @days = due-@now
       
    case @days
      # overdue or due very soon! sound the alarm!
      when -1000..-1
        "<span class=\"red\">" + format_date(due) +"</span>"
      when 0
           "<span class=\"amber\">"+ format_date(due) + "</span>"
      when 1
           "<span class=\"amber\">" + format_date(due) + "</span>"
      # due 2-7 days away
      when 2..7
          "<span class=\"orange\">" + format_date(due) + "</span>"
     # more than a week away - relax
      else
        "<span class=\"green\">" + format_date(due) + "</span>"
    end
  end
  
end
