ActiveRecord::Schema.define(:version => 0) do
    
  create_table "users", :force => true do |t|
    t.string   "name"
  end
    
  create_table "customers", :primary_key => 'cust_id', :force => true do |t|
    t.string "name"
  end
  
end
