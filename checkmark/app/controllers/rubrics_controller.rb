class RubricsController < ApplicationController
  #TODO:  Remove this?  Security hole?
  skip_before_filter :verify_authenticity_token
  
  def index
    @assignment = Assignment.find(params[:id])
  end
  
  def modify
      render :text => params.inspect   
  end
end
