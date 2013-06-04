class TaMembership < Membership
  validate :must_be_a_ta

 def must_be_a_ta
   if user && !user.is_a?(Ta)
     errors.add('User must be a ta')
     false
   end
 end

end
