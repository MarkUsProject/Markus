class RubricsController < ApplicationController
  #TODO:  Remove this?  Security hole?
  skip_before_filter :verify_authenticity_token
  
  def index
    @assignment = Assignment.find(params[:id])
  end
  
  def update
      commands =  ActiveSupport::JSON.decode(params[:commands])
      @assignment = Assignment.find(params[:assignment_id])
      
      commands.each{|command_hash|
       if command_hash['command'] == 'modify'
         rc = RubricCriteria.find(command_hash['id'])
         rc.name = command_hash['name']
         rc.weight = command_hash['weight']
         rc.description = command_hash['description']
         #TODO:  Modify levels too...
         rc.save
         elsif command_hash['command'] == 'new' 
           rc = RubricCriteria.new
           rc.name = command_hash['name']
           rc.weight = command_hash['weight']
           rc.description = command_hash['description']
           rc.assignment = Assignment.find(params[:assignment_id])
           #TODO:  Create levels...
           rc.save
      end
      
      }
      render :text => 'success'
  end
end
