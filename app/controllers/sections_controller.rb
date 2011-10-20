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
      flash[:success] = I18n.t('section.create.success',
                               :name => @section.name)
      redirect_to :action => 'index'
      return
    else
      flash[:error] = I18n.t('section.create.error')
      render :action => 'new'
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
      flash[:success] = I18n.t('section.update.success',
                               :name => @section.name)
      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('section.update.error')
      render :action => 'edit'
    end
  end
end
