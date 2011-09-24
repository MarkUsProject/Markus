class SectionsController < ApplicationController

  before_filter :authorize_only_for_admin

  # Controller corresponding to the users management part

  # Displays sections, and allows to create them
  #TODO Displays metrics concerning users and sections
  def index
    @sections = Section.find(:all)
  end

  def new
    @section = Section.new
  end

  # Creates a new section
  def create
    @section = Section.new(params[:section])
    if @section.save
      flash[:success] = I18n.t('section.create.success')
      redirect_to :action => 'index'
      return
    else
      flash[:error] = reason_for_error(@section.errors, I18n.t('section.create.error'))
      redirect_to :action => 'new'
    end
  end

  # edit a section
  # TODO test
  def edit
    @section = Section.find(params[:id])
  end

  def update
    @section = Section.find(params[:id])
    if @section.update_attributes(params[:section])
      flash[:success] = I18n.t('section.update.success')
      redirect_to :action => 'index'
    else
      flash[:error] = reason_for_error(@section.errors, I18n.t('section.update.error'))
    end
  end
end
