require 'fastercsv'

class RubricsController < ApplicationController
  
  def index
    @assignment = Assignment.find(params[:id])
    @criteria = @assignment.rubric_criterias(:order => 'position')
  end
  
  def add_criterion
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # Create a default Criterion 'New Criterion n'.
    criterion = RubricCriteria.new
    criterion.assignment = @assignment
    criterion.name = 'New Criterion '  +params[:create_num]
    criterion.description = ''
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
     @criterion_levels = [{:name => @criterion.level_0_name, :description => @criterion.level_0_description},
                          {:name => @criterion.level_1_name, :description => @criterion.level_1_description},
                          {:name => @criterion.level_2_name, :description => @criterion.level_2_description},
                          {:name => @criterion.level_3_name, :description => @criterion.level_3_description},
                          {:name => @criterion.level_4_name, :description => @criterion.level_4_description},
     ]

     render :update do |page|
       page.replace_html("rubric_levels_pane_list", :partial => "rubrics/manage/levels", :locals => {:levels => @criterion_levels})
       #Now that the levels have been reloaded, scroll the overflow div back to the top
       page << "$('rubric_levels_pane_list').scrollTop = 0;"
     end      
   end

  
   def remove_criterion
    return unless request.delete?
    criterion = RubricCriteria.find(params[:criterion_id])
    render :update do |page|
      page.visual_effect(:fade, "criterion_#{params[:criterion_id]}", :duration => 0.5)
      page.remove("criterion_#{params[:criterion_id]}")
      #update the sortable criteria list
      page.sortable 'rubric_criteria_pane_list', :constraint => false, :url => { :action => :update_positions }
     end
    #TODO:  Destroy all Rubric Levels for this Criterion
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
     when 'description'
       old_value = criterion.description
       criterion.description = params[:new_value]
     end
     if criterion.valid? && criterion.save
       output = {'status' => 'OK'}
     else
       output = {'status' => 'error', 'old_value' => old_value, 'message' => criterion.errors.full_messages}
     end
     render :json => output.to_json
   end

   def upload_rubric
    file = params[:upload_rubric][:rubric]
    @assignment = Assignment.find(params[:id])
    if request.post? && !file.blank?
      num_update = 0
      flash[:invalid_lines] = []  # store lines that were not processed
      # read each line of the file and update rubric
      # flag
      first_line = true;
      levels = nil;
      FasterCSV.parse(file.read) do |row|
       next if FasterCSV.generate_line(row).strip.empty?
       if first_line #get the row of levels
         levels = row;
         first_line = false;
       elsif add_csv_criterion(row, levels, @assignment) == nil
         flash[:invalid_lines] << row.join(",")
       else
         num_update += 1
       end
      end

      flash[:upload_notice] = "Rubric added/updated."
    end

    redirect_to :action => 'index', :id => @assignment.id, :activate_upload_tab => true
   end

   def add_csv_criterion(values, levels, assignment)
    #must have at least 3 values - name, weight description
    return nil if values.length < 3
    criterion = RubricCriteria.new
    criterion.assignment = assignment
    criterion.name = values[0]
    criterion.weight = values[1]
    criterion.description = values[2]
    criterion.position = RubricCriteria.count + 1
    create_levels(criterion, levels)
    #the rest of the values are level descriptions
    i = 3
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



