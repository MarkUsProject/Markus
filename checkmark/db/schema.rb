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

ActiveRecord::Schema.define(:version => 20081009204754) do

  create_table "annotations", :force => true do |t|
    t.integer "pos_start"
    t.integer "pos_end"
    t.integer "line_start"
    t.integer "line_end"
    t.integer "description_id"
    t.integer "assignmentfile_id"
  end

  add_index "annotations", ["assignmentfile_id"], :name => "index_annotations_on_assignmentfile_id"
  add_index "annotations", ["description_id"], :name => "index_annotations_on_description_id"

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
    t.integer  "group_max",   :default => 1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "assignments", ["name"], :name => "index_assignments_on_name", :unique => true

  create_table "assignments_groups", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "assignment_id"
    t.string  "status"
  end

  add_index "assignments_groups", ["assignment_id", "group_id"], :name => "index_assignments_groups_on_group_id_and_assignment_id", :unique => true

  create_table "categories", :force => true do |t|
    t.text    "name"
    t.text    "token"
    t.integer "ntoken"
  end

  create_table "descriptions", :force => true do |t|
    t.text    "name"
    t.text    "description"
    t.text    "token"
    t.integer "ntoken"
    t.integer "category_id"
    t.integer "assignment_id"
  end

  add_index "descriptions", ["assignment_id"], :name => "index_descriptions_on_assignment_id"
  add_index "descriptions", ["category_id"], :name => "index_descriptions_on_category_id"

  create_table "groups", :force => true do |t|
    t.string "status"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["group_id", "user_id"], :name => "index_memberships_on_user_id_and_group_id", :unique => true

  create_table "rubric_criterias", :force => true do |t|
    t.string   "name",          :null => false
    t.text     "description"
    t.integer  "assignment_id", :null => false
    t.decimal  "weight",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rubric_criterias", ["assignment_id", "name"], :name => "index_rubric_criterias_on_assignment_id_and_name", :unique => true

  create_table "rubric_levels", :force => true do |t|
    t.integer  "rubric_criteria_id", :null => false
    t.string   "name",               :null => false
    t.text     "description"
    t.integer  "level",              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "submission_files", :force => true do |t|
    t.integer  "user_id"
    t.integer  "submission_id"
    t.string   "filename"
    t.datetime "submitted_at"
    t.string   "status"
  end

  add_index "submission_files", ["filename"], :name => "index_submission_files_on_filename"
  add_index "submission_files", ["submission_id"], :name => "index_submission_files_on_submission_id"

  create_table "submissions", :force => true do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.integer "assignment_id"
  end

  create_table "users", :force => true do |t|
    t.string   "user_name",   :null => false
    t.string   "user_number"
    t.string   "last_name"
    t.string   "first_name"
    t.integer  "grace_days"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["user_name"], :name => "index_users_on_user_name", :unique => true
  add_index "users", ["user_number"], :name => "index_users_on_user_number", :unique => true

end
