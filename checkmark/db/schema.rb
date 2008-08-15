# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080812143641) do

  create_table "assignment_files", :force => true do |t|
    t.integer  "assignment_id"
    t.string   "filename",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assignment_files", ["assignment_id", "filename"], :name => "index_assignment_files_on_assignment_id_and_filename", :unique => true

  create_table "assignments", :force => true do |t|
    t.string   "name",                       :null => false
    t.string   "description"
    t.text     "message"
    t.datetime "due_date"
    t.integer  "group_min",   :default => 1, :null => false
    t.integer  "group_max"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assignments", ["name"], :name => "index_assignments_on_name", :unique => true

  create_table "groups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_number"
    t.integer  "assignment_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "groups", ["assignment_id", "user_id"], :name => "index_groups_on_user_id_and_assignment_id", :unique => true
  add_index "groups", ["group_number", "user_id"], :name => "index_groups_on_user_id_and_group_number", :unique => true
  add_index "groups", ["assignment_id", "group_number", "user_id"], :name => "index_groups_on_user_id_and_group_number_and_assignment_id", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "submissions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_number"
    t.integer  "group_id"
    t.integer  "assignment_file_id"
    t.datetime "submitted_at"
  end

  add_index "submissions", ["assignment_file_id", "group_id"], :name => "index_submissions_on_group_id_and_assignment_file_id"
  add_index "submissions", ["group_number", "user_id"], :name => "index_submissions_on_user_id_and_group_number", :unique => true

  create_table "users", :force => true do |t|
    t.string   "user_name",   :null => false
    t.string   "user_number", :null => false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["user_name"], :name => "index_users_on_user_name", :unique => true
  add_index "users", ["user_number"], :name => "index_users_on_user_number", :unique => true

end
