# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 21) do

  create_table "contexts", :force => true do |t|
    t.column "name",     :string,               :default => "", :null => false
    t.column "hide",     :integer, :limit => 4, :default => 0,  :null => false
    t.column "position", :integer,              :default => 0,  :null => false
    t.column "user_id",  :integer,              :default => 0,  :null => false
  end

  create_table "notes", :force => true do |t|
    t.column "user_id",    :integer,  :default => 0, :null => false
    t.column "project_id", :integer,  :default => 0, :null => false
    t.column "body",       :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "open_id_associations", :force => true do |t|
    t.column "server_url", :binary
    t.column "handle",     :string
    t.column "secret",     :binary
    t.column "issued",     :integer
    t.column "lifetime",   :integer
    t.column "assoc_type", :string
  end

  create_table "open_id_nonces", :force => true do |t|
    t.column "nonce",   :string
    t.column "created", :integer
  end

  create_table "open_id_settings", :force => true do |t|
    t.column "setting", :string
    t.column "value",   :binary
  end

  create_table "preferences", :force => true do |t|
    t.column "user_id",                            :integer,               :default => 0,                              :null => false
    t.column "date_format",                        :string,  :limit => 40, :default => "%d/%m/%Y",                     :null => false
    t.column "week_starts",                        :integer,               :default => 0,                              :null => false
    t.column "show_number_completed",              :integer,               :default => 5,                              :null => false
    t.column "staleness_starts",                   :integer,               :default => 7,                              :null => false
    t.column "show_completed_projects_in_sidebar", :boolean,               :default => true,                           :null => false
    t.column "show_hidden_contexts_in_sidebar",    :boolean,               :default => true,                           :null => false
    t.column "due_style",                          :integer,               :default => 0,                              :null => false
    t.column "admin_email",                        :string,                :default => "butshesagirl@rousette.org.uk", :null => false
    t.column "refresh",                            :integer,               :default => 0,                              :null => false
    t.column "verbose_action_descriptors",         :boolean,               :default => false,                          :null => false
    t.column "show_hidden_projects_in_sidebar",    :boolean,               :default => true,                           :null => false
    t.column "time_zone",                          :string,                :default => "London",                       :null => false
  end

  create_table "projects", :force => true do |t|
    t.column "name",        :string,                :default => "",       :null => false
    t.column "position",    :integer,               :default => 0,        :null => false
    t.column "user_id",     :integer,               :default => 0,        :null => false
    t.column "description", :text
    t.column "state",       :string,  :limit => 20, :default => "active", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data",       :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "todos", :force => true do |t|
    t.column "context_id",   :integer,                 :default => 0,           :null => false
    t.column "description",  :string,   :limit => 100, :default => "",          :null => false
    t.column "notes",        :text
    t.column "created_at",   :datetime
    t.column "due",          :date
    t.column "completed_at", :datetime
    t.column "project_id",   :integer
    t.column "user_id",      :integer,                 :default => 0,           :null => false
    t.column "show_from",    :date
    t.column "state",        :string,   :limit => 20,  :default => "immediate", :null => false
  end

  create_table "users", :force => true do |t|
    t.column "login",       :string,  :limit => 80
    t.column "password",    :string,  :limit => 40
    t.column "word",        :string
    t.column "is_admin",    :integer, :limit => 4,  :default => 0,          :null => false
    t.column "first_name",  :string
    t.column "last_name",   :string
    t.column "auth_type",   :string,                :default => "database", :null => false
    t.column "open_id_url", :string
  end

end
