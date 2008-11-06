class RubricsController < ApplicationController
  def index
    @assignment = Assignment.find(params[:id])
  end
  def get
    
  end
end
