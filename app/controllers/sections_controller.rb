class SectionsController < ApplicationController

  before_filter :authorize_only_for_admin

  # Controller corresponding to the users management part

  # Displays sections, and allows to create them
  #TODO Displays metrics concerning users and sections
  def index
    @sections = Section.find(:all)
  end

  # Creates a new section
  def create_section
    return unless request.post?
    @section = Section.new(params[:section])
    if @section.save
      flash[:success] = I18n.t('section.create.success')
      redirect_to :action => 'index'
    else
      flash[:error] = I18n.t('section.create.error')
    end
  end

  # edit a section
  # TODO test
  def edit_section
    @section = Section.find_by_id(params[:id])
    return unless request.post?
      if @section.update_attributes(params[:section])
        flash[:success] = I18n.t('section.update.success')
        redirect_to :action => 'index'
      else
        flash[:error] = I18n.t('section.update.error')
      end
  end
end
