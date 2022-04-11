class AdminRole < Instructor
  validate :associated_user_is_an_admin

  def associated_user_is_an_admin
    unless self.user.nil? || self.user.admin_user?
      errors.add(:base, 'only admin users can be assigned the admin role')
    end
  end
end
