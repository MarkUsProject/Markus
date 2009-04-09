require 'fastercsv'

class RubricsController < ApplicationController

  #max number of rubric levels allowed
  NUM_LEVELS = 5

  def index
    @assignment = Assignment.find(params[:id])
    @criteria = @assignment.rubric_criterias
  end
  
  def add_criterion
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # Create a default Criterion 'New Criterion n'.
    criterion = RubricCriteria.new
    criterion.assignment = @assignment
    criterion.name = 'New Criterion '  +params[:create_num]
    criterion.weight = 1
    criterion.save
    criterion.position = RubricCriteria.count + 1

    # g6mandi: moved level creation to a helper method create_levels for now!
    create_default_levels(criterion)
    
    render :update do |page|
      page.insert_html :bottom, "rubric_criteria_pane_list", 
        :partial => "rubrics/manage/criterion", :locals => { :criterion => criterion }
      #update the sortable criteria list
      page.sortable 'rubric_criteria_pane_list', :constraint => false, :url => { :action => :update_positions }
      page.call(:focus_criterion, criterion.id.to_s)
    end
  end

   def list_levels
     @criterion = RubricCriteria.find(params[:criterion_id])
     @criterion_levels = [{:name => @criterion.level_0_name, :description =>
                          @criterion.level_0_description},
                          {:name => @criterion.level_1_name, :description => @criterion.level_1_description},
                          {:name => @criterion.level_2_name, :description => @criterion.level_2_description},
                          {:name => @criterion.level_3_name, :description => @criterion.level_3_description},
                          {:name => @criterion.level_4_name, :description => @criterion.level_4_description},]

     render :update do |page|
       page.replace_html("rubric_levels_pane_list", :partial => "rubrics/manage/levels", :locals => {:levels => @criterion_levels})
       #Now that the levels have been reloaded, scroll the overflow div back to the top
       page << "$('rubric_levels_pane_list').scrollTop = 0;"
     end      
   end

  
   def remove_criterion
    return unless request.delete?
    criterion = RubricCriteria.find(params[:criterion_id])

     #delete all marks associated with this criterion
    Mark.delete_all(["criterion_id = :c", {:c=>criterion.id}])

    render :update do |page|
      page.visual_effect(:fade, "criterion_#{params[:criterion_id]}", :duration => 0.5)
      page.remove("criterion_#{params[:criterion_id]}")
      #update the sortable criteria list
      page.sortable 'rubric_criteria_pane_list', :constraint => false, :url => { :action => :update_positions }
     end
    criterion.destroy
  end
  
   def update_criterion
     return unless request.post?
     criterion = RubricCriteria.find(params[:criterion_id])
     case params[:update_type]
     when 'name'
         old_value = criterion.name
         criterion.name = params[:new_value]
     when 'weight'
         old_value = criterion.weight
         criterion.weight = params[:new_value]
     end
     if criterion.valid? && criterion.save
       output = {'status' => 'OK'}
     else
       output = {'status' => 'error', 'old_value' => old_value, 'message' => criterion.errors.full_messages}
     end
     render :json => output.to_json
   end
   
   def download_rubric
     @assignment = Assignment.find(params[:id])
     format = params[:format]
     case format
     when "csv"
       file_out = create_csv_rubric(@assignment)
     when "yml"
       file_out = create_yml_rubric(@assignment)
     end
     
     send_data(file_out, :type => "text/csv", :disposition => "inline")
     
   end
   
   #given an assignment, return the names of the levels in the assignment's
   #rubric
   def get_level_names(assignment)
     first_criterion = assignment.rubric_criterias.first
     return nil if first_criterion.nil?
     levels_array = []
     (0..NUM_LEVELS - 1).each do |i|
       levels_array.push(first_criterion['level_' + i.to_s + "_name"])
     end
     return levels_array
   end

   def create_csv_rubric(assignment)
     csv_string = FasterCSV.generate do |csv|
       #first line is level names
       levels_array = get_level_names(assignment)
       csv << levels_array
       assignment.rubric_criterias.each do |criterion|
         criterion_array = [criterion.name,criterion.weight]
         (0..NUM_LEVELS - 1).each do |i|
           criterion_array.push(criterion['level_' + i.to_s + '_description'])
         end
         csv << criterion_array
       end
     end
     return csv_string
   end
   
   def create_yml_rubric(assignment)
     #we reconstruct a yaml object representing a rubric which is
     # {levels => array, criteria => array}
     yml_string = ""
     #need to get the level names from the first criterion
     levels_array = get_level_names(assignment)
     
     #this will store all the criteria objects
     criteria_array = []
     assignment.rubric_criterias.each do |criterion|
        #for each criterion we need to reconstruct a yaml object which is
        # {title => string, weight => int, levels => array}
        
        #get the level_descriptions
        level_descriptions = {}
        (0..NUM_LEVELS - 1).each do |i|
          level_descriptions[i]= criterion['level_' + i.to_s + "_description"]
        end
        
        #this creates the yaml object for a criterion and adds it to the array
        criteria_array.push({"title" => criterion.name,
           "weight" => criterion.weight,
           "levels" => level_descriptions})
     end

     #call to_yaml to generate yaml string for the rubric
     #TODO/FIXME: find a better way to create yaml as to_yaml puts everything in a
     # (seemingly) random order. 
     yml_string << {"levels" => levels_array, "criteria" => criteria_array}.to_yaml
     return yml_string
   end


   def upload_rubric
    file = params[:upload_rubric][:rubric]
    file_type = params[:upload_rubric][:file_type]
    @assignment = Assignment.find(params[:id])
    if request.post? && !file.blank? && !file_type.blank?
      case file_type
      when "csv"
        parse_csv_rubric(file, @assignment)
      when "yml"
        parse_yml_rubric(file, @assignment)
      end
    end

    flash[:upload_notice] = "Rubric added/updated."

    redirect_to :action => 'index', :id => @assignment.id, :activate_upload_tab => true
   end
   
   def parse_csv_rubric(file, assignment)
    num_update = 0
    flash[:invalid_lines] = []  # store lines that were not processed
    # read each line of the file and update rubric
    # flag
    first_line = true;
    levels = nil;
    FasterCSV.parse(file.read) do |row|
     next if FasterCSV.generate_line(row).strip.empty?
     if first_line #get the row of levels
       levels = row
       first_line = false
     elsif add_csv_criterion(row, levels, assignment) == nil
       flash[:invalid_lines] << row.join(",")
     else
       num_update += 1
     end
    end
   end

   def parse_yml_rubric(file, assignment)
     flash[:invalid_lines] = []
     rubric = YAML.load(file.read)
     level_names = rubric["levels"]
     criteria = rubric["criteria"]

     criteria.each do |c|
       criterion = RubricCriteria.new
       criterion.assignment = assignment
       criterion.name = c["title"]
       criterion.weight = c["weight"]
       levels = c["levels"]
       i = 0
       while i < NUM_LEVELS do
         criterion['level_' + i.to_s + '_description'] = levels[i]
         i+=1
       end
       if !criterion.valid? || !criterion.save
         flash[:invalid_lines] << c.to_s
       else
         create_levels(criterion, level_names)
       end
     end
   end

   def add_csv_criterion(values, levels, assignment)
    #must have at least 2 values - name and weight
    return nil if values.length < 2
    criterion = RubricCriteria.new
    criterion.assignment = assignment
    criterion.name = values[0]
    criterion.weight = values[1]
    criterion.position = RubricCriteria.count + 1
    create_levels(criterion, levels)
    #the rest of the values are level descriptions
    i = 2
    while i < values.length do
      criterion['level_' + (i-3).to_s + '_description'] = values[i]
      i+=1
    end
    return nil if !criterion.valid? || !criterion.save

    return criterion
   end

   def create_levels(criterion, levels)
    levels.each_with_index do |level, index|
      criterion['level_' + index.to_s + '_name'] = level
    end
      criterion.save
   end

   # Moved all of this to one helper method for the time being, need to figure out where to put these!
   def create_default_levels(criterion)
    #Create the default levels
    #TODO:  Put these default values in a config file?

    levels=[{'name'=>'Horrible', 'description'=>'This criterion was not satisfied whatsoever', 'disabled'=>false},
      {'name'=>'Satisfactory', 'description'=>'This criterion was satisfied', 'disabled'=>false},
      {'name'=>'Good', 'description'=>'This criterion was satisfied well', 'disabled'=>false},
      {'name'=>'Great', 'description'=>'This criterion was satisfied really well!', 'disabled'=>false},
      {'name'=>'Excellent', 'description'=>'This criterion was satisfied excellently', 'disabled'=>false}]

    levels.each_with_index do |level, index|
      criterion['level_' + index.to_s + '_name'] = level['name']
      criterion['level_' + index.to_s + '_description'] = level['description']
    end
    criterion.save
   end


   def update_level
       criterion = RubricCriteria.find(params[:criterion_id]);
       return unless request.post?
       id = params[:level_index]
       level_name = 'level_'+ id + '_name'
       level_desc = 'level_'+ id + '_description'
       #level = RubricLevel.find(params[:level_id])
       case params[:update_type]
       when 'name' 
         old_value = criterion[level_name]
         criterion[level_name] = params[:new_value]
       when 'description'
         old_value = criterion[level_desc]
         criterion[level_desc] = params[:new_value]
       end
       if criterion.valid? && criterion.save
         output = {'status' => 'OK'}
       else
         output = {'status' => 'error', 'old_value' => old_value}
       end
       render :json => output.to_json
  end
  
  #This method handles the drag/drop RubricCriteria sorting
  def update_positions
    params[:rubric_criteria_pane_list].each_with_index do |id, position|
      RubricCriteria.update(id, :position => position+1)
    end
    render :nothing => true
  end

end



