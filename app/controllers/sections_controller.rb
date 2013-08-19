class SectionsController < ApplicationController

  before_filter :authorize_only_for_admin

  # Controller corresponding to the users management part

  # Displays sections, and allows to create them
  #TODO Displays metrics concerning users and sections
  def index
    @sections = Section.all
  end

  def new
    @section = Section.new
  end

  # Creates a new section
  def create
    @user = Student.new(params[:user])

    @section = Section.new(params[:section])
    if @section.save
      @sections = Section.all
      flash[:success] = I18n.t('section.create.success', :name => @section.name)
      if params[:section_modal]
        render 'close_modal_add_section'
        return
      end
      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('section.create.error')
      if params[:section_modal]
        render 'add_new_section_handler'
        return
      end
      render :new
    end
  end

  # edit a section
  def edit
    @section = Section.find(params[:id])
    @students = @section.students
  end

  def update
    @section = Section.find(params[:id])
    if @section.update_attributes(params[:section])
      flash[:success] = I18n.t('section.update.success', :name => @section.name)
      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('section.update.error')
      render :edit
    end
  end

  def destroy
    @section = Section.find(params[:id])

    # only destroy section if this user is allowed to do so and the section has no students
    if @section.user_can_modify?(current_user)
      if @section.has_students?
        flash[:error] = I18n.t('section.delete.not_empty')
      else
        @section.destroy
        flash[:success] = I18n.t('section.delete.success')
      end
    else
      flash[:error] = I18n.t('section.delete.error_permissions')
    end
    redirect_to :action => :index
  end
end
