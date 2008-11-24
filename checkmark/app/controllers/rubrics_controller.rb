class RubricsController < ApplicationController
  
  def index
    @assignment = Assignment.find(params[:id])
  end
  
  def add_criterion
    return unless request.post?
    @assignment = Assignment.find(params[:id])
    # Create new group for this assignment
    criterion = RubricCriteria.new
    criterion.assignment = @assignment
    criterion.name = 'New Criterion '  +params[:create_num]
    criterion.description = ''
    criterion.weight = 1
    criterion.save
    
    #Create the default levels
    #TODO:  Put these default values in a config file?
    levels=[{'name'=>'Horrible', 'description'=>'This criterion was not satisfied whatsoever', 'disabled'=>false}, 
      {'name'=>'Satisfactory', 'description'=>'This criterion was satisfied', 'disabled'=>false},
      {'name'=>'Good', 'description'=>'This criterion was satisfied well', 'disabled'=>false},
      {'name'=>'Excellent', 'description'=>'This criterion was satisfied excellently', 'disabled'=>false}]
    levels.each_with_index do |level, index|
      new_level = RubricLevel.new
      new_level.name = level['name']
      new_level.description = level['description']
      new_level.level = index
      new_level.rubric_criteria = criterion
      new_level.save
      
      
    end
    
    render :update do |page|
      page.insert_html :bottom, "rubric_criteria_pane_list", 
        :partial => "rubrics/manage/criterion", :locals => { :criterion => criterion }
      #update the sortable criteria list
      page.sortable 'rubric_criteria_pane_list', :constraint => false, :url => { :action => :update_positions }
      page.call(:focus_criterion, criterion.id.to_s)

      
    end
  end

   def list_levels
     @criterion_levels = RubricLevel.find_all_by_rubric_criteria_id(params[:criterion_id], :order=>'level')
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
       output = {'status' => 'error', 'old_value' => old_value}
     end
     render :json => output.to_json
   end

   def update_level
       return unless request.post?
       level = RubricLevel.find(params[:level_id])
       case params[:update_type]
       when 'name' 
           old_value = level.name
           level.name = params[:new_value]
       when 'description'
         old_value = level.description
         level.description = params[:new_value]
       end
       if level.valid? && level.save
         output = {'status' => 'OK'}
       else
         output = {'status' => 'error', 'old_value' => old_value}
       end
       render :json => output.to_json
  end
  
  #This method handles the drag/drop RubricCriteria sorting
  def update_positions
    params[:sortable_list].each_with_index do |id, position|
      RubricCriteria.update(id, :position => position+1)
    end
    render :nothing => true
  end

end

