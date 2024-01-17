module TodoHelper

  require 'user_controller'
  # Counts the number of uncompleted items in the specified context
  #
  def count_items(context)
    count = Todo.find_all("done=0 AND context_id=#{context.id}").length
  end

  def form_remote_tag_edit_todo( item, type )
    (type == "deferred") ? act = 'update' : act = 'update_action'
    (type == "deferred") ? controller_name = 'deferred' : controller_name = 'todo'
    form_remote_tag( :url => { :controller => controller_name, :action => act, :id => item.id },
                    :html => { :id => "form-action-#{item.id}", :class => "inline-form" }
                   )
  end
  
  def link_to_remote_todo( item, handled_by, type)
    (type == "deferred") ? destroy_act = 'destroy' : destroy_act = 'destroy_action'
    str = link_to_remote( image_tag("blank", :title =>"Delete action", :class=>"delete_item"),
                      {:url => { :controller => handled_by, :action => destroy_act, :id => item.id },
                      :confirm => "Are you sure that you want to delete the action, \'#{item.description}\'?"},
                        {:class => "icon"}) + "\n"
    if !item.done?
      (type == "deferred") ? edit_act = 'edit' : edit_act = 'edit_action'
      str << link_to_remote( image_tag("blank", :title =>"Edit action", :class=>"edit_item", :id=>"action-#{item.id}-edit-icon"),
                      {
                        :update => "form-action-#{item.id}",
                        :loading => visual_effect(:pulsate, "action-#{item.id}-edit-icon"),
                        :url => { :controller => handled_by, :action => edit_act, :id => item.id },
                        :success => "Element.toggle('item-#{item.id}','action-#{item.id}-edit-form'); new Effect.Appear('action-#{item.id}-edit-form', { duration: .2 });  Form.focusFirstElement('form-action-#{item.id}')"
                      },
                      {
                        :class => "icon"
                      })
    else
      str << '<a class="icon">' + image_tag("blank") + "</a> "
    end
    str
  end
  
  # Uses the 'staleness_starts' value from settings.yml (in days) to colour
  # the background of the action appropriately according to the age
  # of the creation date:
  # * l1: created more than 1 x staleness_starts, but < 2 x staleness_starts
  # * l2: created more than 2 x staleness_starts, but < 3 x staleness_starts
  # * l3: created more than 3 x staleness_starts
  #
  def staleness_class(item)
    if item.due || item.done?
      return ""
    elsif item.created_at < (@user.preferences["staleness_starts"].to_i*3).days.ago
      return " stale_l3"
    elsif item.created_at < (@user.preferences["staleness_starts"].to_i*2).days.ago
      return " stale_l2"
    elsif item.created_at < (@user.preferences["staleness_starts"].to_i).days.ago
      return " stale_l1"
    else
      return ""
    end
  end

  # Check show_from date in comparison to today's date
  # Flag up date appropriately with a 'traffic light' colour code
  #
  def show_date(due)
    if due == nil
      return ""
    end

    @now = Date.today
    @days = due-@now
       
    case @days
      # overdue or due very soon! sound the alarm!
      when -1000..-1
        "<a title='" + format_date(due) + "'><span class=\"red\">Shown on " + (@days * -1).to_s + " days</span></a> "
      when 0
           "<a title='" + format_date(due) + "'><span class=\"amber\">Show Today</span></a> "
      when 1
           "<a title='" + format_date(due) + "'><span class=\"amber\">Show Tomorrow</span></a> "
      # due 2-7 days away
      when 2..7
      if @user.preferences["due_style"] == "1"
        "<a title='" + format_date(due) + "'><span class=\"orange\">Show on " + due.strftime("%A") + "</span></a> "
      else
        "<a title='" + format_date(due) + "'><span class=\"orange\">Show in " + @days.to_s + " days</span></a> "
      end
      # more than a week away - relax
      else
        "<a title='" + format_date(due) + "'><span class=\"green\">Show in " + @days.to_s + " days</span></a> "
    end
  end

  def toggle_show_notes( item )
    str = "<a href=\"javascript:Element.toggle('"
    str << item.id.to_s
    str << "')\" class=\"show_notes\" title=\"Show notes\">"
    str << image_tag( "blank", :width=>"16", :height=>"16", :border=>"0" ) + "</a>"
    m_notes = markdown( item.notes )
    str << "\n<div class=\"notes\" id=\"" + item.id.to_s + "\" style=\"display:none\">"
    str << m_notes + "</div>"
    str
  end
  
  def calendar_setup( input_field )
    date_format = @user.preferences["date_format"]
    week_starts = @user.preferences["week_starts"]
    str = "Calendar.setup({ ifFormat:\"#{date_format}\""
    str << ",firstDay:#{week_starts},showOthers:true,range:[2004, 2010]"
    str << ",step:1,inputField:\"" + input_field + "\",cache:true,align:\"TR\" })\n"
    javascript_tag str
  end
  
  def rss_feed_link(options = {})
    image_tag = image_tag("feed-icon", :size => "16X16", :border => 0, :class => "rss-icon")
    linkoptions = {:controller => 'feed', :action => 'rss', :name => "#{@user.login}", :token => "#{@user.word}"}
    linkoptions.merge!(options)
		link_to(image_tag, linkoptions, :title => "RSS feed")
  end
  
  def text_feed_link(options = {})
    linkoptions = {:controller => 'feed', :action => 'text', :name => "#{@user.login}", :token => "#{@user.word}"}
    linkoptions.merge!(options)
    link_to('<span class="feed">TXT</span>', linkoptions, :title => "Plain text feed" )
  end
  
  def ical_feed_link(options = {})
    linkoptions = {:controller => 'feed', :action => 'ical', :name => "#{@user.login}", :token => "#{@user.word}"}
    linkoptions.merge!(options)
    link_to('<span class="feed">iCal</span>', linkoptions, :title => "iCal feed")
  end
  
end
