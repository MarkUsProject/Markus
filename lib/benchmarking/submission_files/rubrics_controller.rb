require 'fastercsv'

class RubricsController < ApplicationController

  before_filter      :authorize_only_for_admin

  #max number of rubric levels allowed
  NUM_LEVELS = 5

  def index
    @assignment = Assignment.find(params[:id])
    @criteria = @assignment.rubric_criteria(:order => 'position')
  end

  def edit
    @criterion = RubricCriterion.find(params[:id])
  end

  def update
    @criterion = RubricCriterion.find(params[:id])
    @criterion.update_attributes(params[:rubric_criterion])
    unless @criterion.save
      render :errors
      return
    end
    flash.now[:success] = I18n.t('criterion_saved_success')
  end

  def new
    @assignment = Assignment.find(params[:id])
    if request.post?
      @criterion = RubricCriterion.new
      @criterion.assignment = @assignment
      @criterion.update_attributes(params[:rubric_criterion])
      @criterion.weight = RubricCriterion::DEFAULT_WEIGHT
      @criterion.set_default_levels
      unless @criterion.save
        flash.now[:error] = I18n.t('criterion_created_error')
        render :show_help
      end
      render :create_and_edit
    end
  end

  def delete
    return unless request.delete?
    @criterion = RubricCriterion.find(params[:id])
     #delete all marks associated with this criterion
    Mark.delete_all(['rubric_criterion_id = :c', {:c => @criterion.id}])
    @criterion.destroy
    flash.now[:success] = I18n.t('criterion_deleted_success')
  end

  def download_rubric
     @assignment = Assignment.find(params[:id])
     format = params[:format]
     case format
     when 'csv'
       file_out = create_csv_rubric(@assignment)
     when 'yml'
       file_out = create_yml_rubric(@assignment)
     end
     send_data(file_out, :type => 'text/csv', :disposition => 'inline')
   end

   #given an assignment, return the names of the levels in the assignment's
   #rubric
   def get_level_names(assignment)
     first_criterion = assignment.rubric_criteria.first
     return nil if first_criterion.nil?
     levels_array = []
     (0..NUM_LEVELS - 1).each do |i|
       levels_array.push(first_criterion['level_' + i.to_s + '_name'])
     end
     levels_array
   end

   def create_csv_rubric(assignment)
     csv_string = FasterCSV.generate do |csv|
       #first line is level names
       levels_array = get_level_names(assignment)
       csv << levels_array
       assignment.rubric_criteria.each do |criterion|
         criterion_array = [criterion.rubric_criterion_name,criterion.weight]
         (0..NUM_LEVELS - 1).each do |i|
           criterion_array.push(criterion['level_' + i.to_s + '_description'])
         end
         csv << criterion_array
       end
     end
     csv_string
   end

   def create_yml_rubric(assignment)
     #we reconstruct a yaml object representing a rubric which is
     # {levels => array, criteria => array}
     yml_string = ''
     #need to get the level names from the first criterion
     levels_array = get_level_names(assignment)

     #this will store all the criteria objects
     criteria_array = []
     assignment.rubric_criteria.each do |criterion|
        #for each criterion we need to reconstruct a yaml object which is
        # {title => string, weight => int, levels => array}

        #get the level_descriptions
        level_descriptions = {}
        (0..NUM_LEVELS - 1).each do |i|
          level_descriptions[i]= criterion['level_' + i.to_s + '_description']
        end

        #this creates the yaml object for a criterion and adds it to the array
        criteria_array.push({'title' => criterion.rubric_criterion_name,
           'weight' => criterion.weight,
           'levels' => level_descriptions})
     end

     #call to_yaml to generate yaml string for the rubric
     #TODO/FIXME: find a better way to create yaml as to_yaml puts everything in a
     # (seemingly) random order.
     yml_string << {'levels' => levels_array, 'criteria' => criteria_array}.to_yaml
     yml_string
   end


   def upload_rubric
    file = params[:upload_rubric][:rubric]
    file_type = params[:upload_rubric][:file_type]
    @assignment = Assignment.find(params[:id])
    if request.post? && !file.blank? && !file_type.blank?
      begin
        RubricCriterion.transaction do
          case file_type
          when 'csv'
            parse_csv_rubric(file, @assignment)
          when 'yml'
            parse_yml_rubric(file, @assignment)
          end
          unless flash[:invalid_lines].empty?
            raise I18n.t('csv_invalid_lines')
          end
          flash[:success] = 'Rubric added/updated.'
        end
      rescue Exception => e
        flash[:error] = I18n.t('csv_valid_format')
      end
    end



    redirect_to :action => 'index', :id => @assignment.id
   end

   def parse_csv_rubric(file, assignment)
    num_update = 0
    flash[:invalid_lines] = []  # store lines that were not processed
    # read each line of the file and update rubric
    # flag
    first_line = true
    levels = nil
    FasterCSV.parse(file.read) do |row|
     next if FasterCSV.generate_line(row).strip.empty?
     begin
       if first_line #get the row of levels
         levels = row
         first_line = false
       elsif add_csv_criterion(row, levels, assignment) == nil
         raise row.join(',')
       else
         num_update += 1
       end
     rescue RuntimeError => e
       flash[:invalid_lines] << e.message
     end
    end
   end

   def parse_yml_rubric(file, assignment)
     flash.now[:invalid_lines] = []
     rubric = YAML.load(file.read)
     level_names = rubric['levels']
     criteria = rubric['criteria']

     criteria.each do |c|
       criterion = RubricCriterion.new
       criterion.assignment = assignment
       criterion.rubric_criterion_name = c['title']
       criterion.weight = c['weight']
       criterion.position = assignment.rubric_criteria.maximum('position') + 1
       levels = c['levels']
       i = 0
       0..NUM_LEVELS do |i|
         criterion['level_' + i.to_s + '_description'] = levels[i]
       end
       if !criterion.valid? || !criterion.save
         flash.now[:invalid_lines] << c.to_s
       else
         create_levels(criterion, level_names)
       end
     end
   end

   def add_csv_criterion(values, levels, assignment)
    #must have at least 2 values - name and weight
    return nil if values.length < 2
    criterion = RubricCriterion.new
    criterion.assignment = assignment
    criterion.rubric_criterion_name = values.shift
    criterion.weight = values.shift
    criterion.position = assignment.rubric_criteria.maximum('position') + 1
    create_levels(criterion, levels)
    #the rest of the values are level descriptions
    values.each_with_index do |value, index|
      criterion['level_' + index.to_s + '_description'] = value
    end
    return nil if !criterion.valid? || !criterion.save
    criterion
   end

   def create_levels(criterion, levels)
    levels.each_with_index do |level, index|
      criterion['level_' + index.to_s + '_name'] = level
    end
      criterion.save
   end

  #This method handles the drag/drop RubricCriteria sorting
  def update_positions
    params[:rubric_criteria_pane_list].each_with_index do |id, position|
      if id != ''
        RubricCriterion.update(id, :position => position+1)
      end
    end
    render :nothing => true
  end

end



