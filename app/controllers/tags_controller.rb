class TagsController < ApplicationController

  before_filter :authorize_only_for_admin

  def index
    @assignment = Assignment.find(params[:assignment_id])
  end

  # Creates a new instance of the tag.
  def create
    @text = Tag.create({
      content: params[:content],
      creator_id: current_user.id,
      luser_id: current_user.id
      })
  end

  # Destroys a particular tag.
  def destroy
    @tag = Tags.find(params[:id])
    @tag.destroy
  end
end