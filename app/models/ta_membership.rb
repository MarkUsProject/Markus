class TaMembership < Membership
  before_validation :must_be_a_ta

 def must_be_a_ta
   if user && !user.is_a?(Ta)
      errors.add_to_base("User must be a ta")
      return false
   end
 end

end
