class TagsController < ApplicationController
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