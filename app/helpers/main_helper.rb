module MainHelper

  protected

  # Sets current user for this session
  def current_user=(user)
    session[:user_name] = user&.is_a?(User) ? user.user_name : nil
  end

  def real_user=(user)
    session[:real_user_name] = user&.is_a?(User) ? user.user_name : nil
  end

  def get_blank_message(login, password)
    if login.blank? && password.blank?
      I18n.t('main.username_and_password_not_blank')
    elsif login.blank?
      I18n.t('main.username_not_blank')
    elsif password.blank?
      I18n.t('main.password_not_blank')
    end
  end
end
