class AnnotationsController < ApplicationController
  
  def index
    @assignments = Assignment.all(:order => :id)

  end
  
  def add_existing_annotation
    label = AnnotationLabel.find(params[:annotation_label_id])
    new_annotation = { 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_label_id => label.id,
      :submission_file_id => params[:submission_file_id]
    }
    @submission_file_id = params[:submission_file_id]
    annotation = Annotation.new(new_annotation)
    annotation.save
    annots = Annotation.find_all_by_submission_file_id(@submission_file_id, :order => "line_start") || []

    render :update do |page|
      page.call(:add_annotation_label, label.id, label.content)
      page << "add_annotation(#{annotation.id},$R(#{params[:line_start]}, #{params[:line_end]}), #{label.id})"
      page.replace_html 'annotation_summary_list', :partial => 'annotation_summary', :locals => {:annots => annots, :submission_file_id => @submission_file_id}

    end

  end

  def create
   
    new_label = {
      :content => params[:annotation_text],
      :annotation_category_id => params[:category_id]
    }
    label = AnnotationLabel.new(new_label)
    label.save
    
    @submission_file_id = params[:submission_file_id]
    
    new_annotation = { 
      :line_start => params[:line_start], 
      :line_end => params[:line_end],
      :annotation_label_id => label.id,
      :submission_file_id => params[:submission_file_id]
    }
    annotation = Annotation.new(new_annotation)
    annotation.save

    annots = Annotation.find_all_by_submission_file_id(@submission_file_id, :order => "line_start") || []

    render :update do |page|
      page.replace_html 'annotation_summary_list', :partial => 'annotation_summary', :locals => {:annots => annots, :submission_file_id => @submission_file_id}
      if(label.annotation_category_id != nil) 
        page.replace_html "annotation_label_list_#{label.annotation_category_id}", :partial => 'annotation_list', :locals => {:annotation_category => label.annotation_category}
      end
      
      page.call(:add_annotation_label, label.id, label.content)
      page << "add_annotation(#{annotation.id},$R(#{params[:line_start]}, #{params[:line_end]}), #{label.id})"

    end
    
  end

  def destroy
    @annot = Annotation.find(params[:id])
    old_annot = @annot.destroy
    @submission_file_id = params[:submission_file_id]
    annots = Annotation.find_all_by_submission_file_id(params[:submission_file_id], :order => "line_start") || []
    render :update do |page|
      page << "remove_annotation(#{old_annot.id}, $R(#{old_annot.line_start}, #{old_annot.line_end}), #{old_annot.annotation_label.id});"
      page.replace_html 'annotation_summary_list', :partial => 'annotation_summary', :locals => {:annots => annots, :submission_file_id => @submission_file_id}
      
    end
  end

  def students
    @students = User.students
    @aid = params[:id]
    @assignment = Assignment.find(@aid)
  end

  def grader
    @assignment = Assignment.find(params[:aid])
    @rubric_criteria = @assignment.rubric_criterias(:order => 'position')
    @annotation_categories = @assignment.annotation_categories
    @user = User.find(params[:uid])
    @uid = @user.id
    submission = @assignment.submission_by(@user)
    @files = submission.submitted_filenames || []
    #Get the result object
    @result = Result.find_by_submission_id(submission.id)
    if (@result == nil)
      @result = Result.new(:submission_id=>submission.id, :marking_state=>"unmarked");
      @result.save
    end
    #link marks and criterias together
    @marks_map = []
    @rubric_criteria.each do |criterion|
      mark = Mark.find(:first,
        :conditions => ["result_id = :r AND rubric_criteria_id = :c", {:r=> @result.id, :c=>criterion.id}] )
      if mark.nil?
        mark = Mark.new(:result_id=>@result.id, :rubric_criteria_id=>criterion.id)
        #save even though there is no mark yet
        mark.save(false)
      end
      @marks_map[criterion.id] = mark
    end
  end

  def codeviewer
    @assignment = Assignment.find(params[:id])
    submission = @assignment.submission_by(User.find(params[:uid]))
    @submission_file_id = params[:submission_file_id]
    file = SubmissionFile.find(@submission_file_id)
    annots = Annotation.find_all_by_submission_file_id(@submission_file_id, :order => "line_start") || []
    dir = submission.submit_dir

    filepath = File.join(dir, file.filename)

    filetext = File.read(filepath)
    
    #@code_type = file.get_file_type
    @code_type = 'ruby'
    
    render :update do |page|

      #Render the source code for syntax highlighting...
      page.replace_html 'codeviewer', :partial => 'codeviewer', :locals => 
        { :uid => params[:uid], :filetext => filetext, :annots => annots, :code_type => @code_type}
      #Also update the annotation_summary_list
      page.replace_html 'annotation_summary_list', :partial => 'annotation_summary', :locals => {:annots => annots, :submission_file_id => @submission_file_id}

    end      
    
  end

  #Update the mark for a specific criterion
  def update_mark
    mark = Mark.find(params[:mark_id]);
    old_mark = mark.mark;
    criterion = RubricCriteria.find(mark.rubric_criteria_id);
    mark.mark = params[:mark];
    mark.save
    #update the total mark
    result = Result.find(mark.result_id)
    result.marking_state = "partial"
    result.calculate_total
    result.save
    render :update do |page|
      if !old_mark.nil?
        #Change the css class of the old level to make it appear unselected
        page["criterion_#{criterion.id}_level_#{old_mark}"].removeClassName("criterion_level_selected")
        page["criterion_#{criterion.id}_level_#{old_mark}"].addClassName("criterion_level")
      end
      
      #Change the css class of the new level to make it appear selected
      page["criterion_#{criterion.id}_level_#{mark.mark}"].removeClassName("criterion_level")
      page["criterion_#{criterion.id}_level_#{mark.mark}"].addClassName("criterion_level_selected")

      #we need to update the following items to reflect the new mark
      #1 the mark in the criterion holder itself
      page.replace_html("criterion_title_#{mark.id}_mark",
              "<b>"+ mark.mark.to_s + "&nbsp;" +
              criterion["level_" + mark.mark.to_s + "_name"] + "</b> &nbsp;" +
              criterion["level_" + mark.mark.to_s + "_description"])
      #2 The subtotal div in summary pane
      page.replace_html("current_subtotal_div", result.get_subtotal)
      #3 Total mark div in summary pane
      page.replace_html("current_total_mark_div", result.total_mark)
      #4 The mark as it appears in the summary view
      page.replace_html("mark_summary_#{mark.id}_mark",  mark.mark.to_s)
      #5 Need to update the grade for the criterion
      page.replace_html("mark_summary_#{mark.id}_grade",
        (mark.mark*criterion.weight).to_s +
        " / " + (criterion.weight * 4).to_s)
      #6 total mark div at the top of the page
      page.replace_html("current_mark_div", result.total_mark)
      
    end
  end
  
  def update_annotation
    content = params[:annotation_label][:content]
    id = params[:annotation_label][:id]
    @submission_file_id = params[:annotation_label][:submission_file_id]
    
    annotation_label = AnnotationLabel.find(id)
    annotation_label.content = content
    annotation_label.save
 
    annots = Annotation.find_all_by_submission_file_id(@submission_file_id, :order => "line_start") || []
    render :update do |page|
      page.replace_html 'annotation_summary_list', :partial => 'annotation_summary', :locals => {:annots => annots, :submission_file_id => @submission_file_id}
      if(annotation_label.annotation_category_id != nil) 
        page.replace_html "annotation_label_list_#{annotation_label.annotation_category_id}", :partial => 'annotation_list', :locals => {:annotation_category => annotation_label.annotation_category}
      end

      page.call(:update_annotation_label, id, content)
    end 

  end

  #Updates the overall comment from the annotations tab
  def update_comment
    result = Result.find(params[:result_id])
    result.overall_comment = params[:overall_comment]
    result.save;
    render :update do |page|
    end
  end

  #Updates the marking state
  def update_marking_state
    result = Result.find(params[:id])
    result.marking_state = params[:value]
    result.save;
    render :update do |page|
    end
  end

  #Adds a new extra mark object and inserts it into the html
  def add_extra_mark
    extra_mark = ExtraMark.new(:result_id => params[:id], :mark => 0, :description=>"New Extra Mark");
    extra_mark.save;
    render :update do |page|
      #insert the new mark into the bottom of the table and focus it
      page.insert_html :bottom, "extra_marks_list",
        :partial => "annotations/extra_mark", :locals => { :mark => extra_mark }
      page.call(:focus_extra_mark, extra_mark.id.to_s)
    end
  end

  #Deletes an extra mark from the database and removes it from the html
  def remove_extra_mark
    #find the extra mark and destroy it
    extra_mark = ExtraMark.find(params[:mark_id])
    extra_mark.destroy
    #need to recalculate total mark
    result = Result.find(extra_mark.result_id)
    result.calculate_total
    render :update do |page|
      #delete it from the html
      page.remove("extra_mark_#{params[:mark_id]}")
      page.replace_html("current_total_mark_div", result.total_mark)
    end
  end

  #update the mark and/or description of the extra mark
  def update_extra_mark
    extra_mark = ExtraMark.find(params[:id])
    #the attribute to be changed - description or mark
    type = params[:type]
    #the new attribute value
    val = params[:value]
    #change the value
    extra_mark[type] = val

    #save it
    if extra_mark.valid? && extra_mark.save
      #need to update the total mark
      result = Result.find(extra_mark.result_id)
      result.calculate_total
      render :update do |page|
        #The following divs need to be changed
        #1 the display of the extra mark
        page.replace_html("extra_mark_title_#{extra_mark.id}_" + type, val)
        #2 the display of the total mark
        page.replace_html("current_total_mark_div", result.total_mark)
        #3 the divs containing deductions/bonuses
        page.replace_html("extra_marks_bonus", result.get_bonus_marks)
        page.replace_html("extra_marks_deducted", result.get_deductions)
        #4 the div containing the total mark at the top of the page
        page.replace_html("current_mark_div", result.total_mark)
      end
    else
      output = {'status' => 'error'}
      render :json => output.to_json
    end
  end

  #should be moved to javascript, but put here for now, since we can easily access all
  #unmarked criterion here.
  def expand_criteria
    #true if we want to expand, false to collapse
    expand = params[:expand]
    #true if we only want to expand the unmarked portion
    unmarked = params[:unmarked]
    assignment = Assignment.find(params[:aid])
    result = Result.find(params[:rid])
    criteria = assignment.rubric_criterias
    render :update do |page|
      criteria.each do |criterion|
        mark = Mark.find(:first,
              :conditions => ["result_id = :r AND rubric_criteria_id = :c", {:r=> result.id, :c=>criterion.id}] )
        html = "+ &nbsp;"
        if expand #if we want to expand criteria...
          #if we want to expand ony unmarked assignments, expand ones where the
          #mark is nil
          if (unmarked and mark.mark.nil?) or not unmarked
            html = "- &nbsp;"
            page["criterion_inputs_#{criterion.id}"].show();
          end
        else
          page["criterion_inputs_#{criterion.id}"].hide();
          page["criterion_title_#{criterion.id}"].show();
        end
        page["criterion_title_#{criterion.id}_expand"].innerHTML = html 
      end
    end
  end

  #Creates a gradesfile in the format specified by
  #http://www.cs.toronto.edu/~clarke/grade/new/fileformat.html

  def get_gradesfile
    file_out = ""
    assignments = Assignment.find(:all, :order => "id")
    students = User.find_all_by_role('student')
    results = Result.find(:all)
    #need to create the header, which is the list of assignments and their total
    #mark
    assignments.each do |asst|
      str = asst.name.tr(" ", "") + ' / ' + asst.total_mark.to_s;
      file_out << str + "\n"
    end

    file_out << "\n"
   
    #next we generate the list of students and marks
    #student# + four spaces + student last name + 2 spaces + student first name
    # + marks (each preceded by a tab char)
    students.each do |student|
      str = ""
      str << student.user_number + "    " + student.last_name + "  " + student.first_name

      #for each assignment add the mark to the line
      assignments.each do |asst|
        #get the student's group for this assignment
        group = asst.group_by(student.id);
        next if group.nil?
        #find the corresponding submission
        sub = Submission.find_by_group_id(group.id)
        next if sub.nil?
        #find the corresponding result
        result = Result.find_by_submission_id(sub.id)
        next if result.nil?
        str << "\t" + result.total_mark.to_s
      end

      file_out << str + "\n"
    end

    send_data(file_out, :type => "text", :disposition => "inline")
  end
  
end
