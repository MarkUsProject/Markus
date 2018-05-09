class TaMembership < Membership
  validate :must_be_a_ta

  after_create   { Repository.get_class.update_permissions }
  after_destroy  { Repository.get_class.update_permissions }

 def must_be_a_ta
   if user && !user.is_a?(Ta)
     errors.add('base', 'User must be a ta')
     false
   end
 end

end
