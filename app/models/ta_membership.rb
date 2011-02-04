class TaMembership < Membership

 def validate
      errors.add(:base, "User must be a ta") if user && !user.is_a?(Ta)
 end

end
