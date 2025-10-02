class SectionsController < ApplicationController
  before_action { authorize! }

  layout 'assignment_content'

  # Controller corresponding to the users management part

  # Displays sections, and allows to create them
  # TODO Displays metrics concerning users and sections
  def index
    @sections = current_course.sections.includes(:students)
  end

  def new
    @section = current_course.sections.new
  end

  # Creates a new section
  def create
    @section = current_course.sections.new(section_params)
    if @section.save
      @sections = current_course.sections
      flash_message(:success, t('.success', name: @section.name))
      if params[:section_modal]
        render 'close_modal_add_section'
        return
      end
      redirect_to action: 'index'
    else
      flash_message(:error, t('.error'))
      if params[:section_modal]
        render 'add_new_section_handler'
        return
      end
      render :new
    end
  end

  # edit a section
  def edit
    @section = record
    @students = @section.students
  end

  def update
    @section = record
    if @section.update(section_params)
      flash_message(:success, t('.success', name: @section.name))
      redirect_to action: 'index'
    else
      flash_message(:error, t('.error'))
      render :edit
    end
  end

  def destroy
    @section = record

    if @section.has_students?
      flash_message(:error, t('.not_empty'))
    else
      @section.destroy
      flash_message(:success, t('.success'))
    end
    redirect_to action: :index
  end

  private

  def section_params
    params.require(:section).permit(:name)
  end
end
