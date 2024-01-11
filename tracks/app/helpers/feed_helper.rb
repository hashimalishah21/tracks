module FeedHelper

  # Build a nicely formatted text string for display
  # Context forms the heading, then the items are
  # indented underneath. If there is a due date
  # and the item is in a project, these are also displayed
  #
  def build_text_page(list,context)
    result_string = ""
      result_string << "\n" + context.name.upcase + ":\n"

      list.each do |item|
      if item.context_id == context.id

        if item.due
          result_string << "    [" + format_date(item.due) + "] "
          result_string << item.description + " "
        else
          result_string << "    " + item.description + " "
        end

        if item.project_id
          result_string << "(" + item.project.name + ")"
        end
      result_string << "\n"
      end

      end
    return result_string
  end
  
end
