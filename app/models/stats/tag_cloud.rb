# tag cloud code inspired by this article
#  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
module Stats
  class TagCloud

    attr_reader :user, :cutoff, :levels
    def initialize(user, cutoff = nil)
      @user = user
      @cutoff = cutoff
      @levels = 10
    end

    def empty?
      tags.empty?
    end

    def font_size(tag)
      (9 + 2*(tag.count.to_i-min)/divisor)
    end

    def tags
      @tags ||= top_tags
    end

    private

    def max
      @max ||= counts.max
    end

    def min
      @min ||= counts.min
    end

    def divisor
      @divisor ||= ((max - min) / levels) + 1
    end

    def counts
      @counts ||= tags.map {|t| t.count.to_i}
    end

    def top_tags
      Tag.find_by_sql(query_options).sort_by { |tag| tag.name.downcase }
    end

    def query_options
      options = [sql, user.id]
      options += [cutoff, cutoff] if cutoff
      options
    end

    def sql
      # TODO: parameterize limit
      query = "SELECT tags.id, tags.name AS name, count(*) AS count"
      query << " FROM taggings, tags, todos"
      query << " WHERE tags.id = tag_id"
      query << " AND todos.user_id=? "
      query << " AND taggings.taggable_type='Todo' "
      query << " AND taggings.taggable_id=todos.id "
      if cutoff
        query << " AND (todos.created_at > ? OR "
        query << "      todos.completed_at > ?) "
      end
      query << " GROUP BY tags.id, tags.name"
      query << " ORDER BY count DESC, name"
      query << " LIMIT 100"
    end

  end
end
