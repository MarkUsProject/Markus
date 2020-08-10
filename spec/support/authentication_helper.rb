module AuthenticationHelper
  def sign_in(user)
    real_controller = @controller
    @controller = MainController.new
    post :login, params: { user_login: user.user_name, user_password: 'x' }
    @controller = real_controller
  end

  def get_as(user, action, params: {}, format: nil, session: {})
    sign_in user
    get action, xhr: true, params: params, format: format, session: session
  end

  # Performs POST request as the supplied user for authentication
  def post_as(user, action, params: {}, format: nil, session: {})
    sign_in user
    post action, xhr: true, params: params, format: format, session: session
  end

  # Performs PUT request as the supplied user for authentication
  def put_as(user, action, params: {}, format: nil, session: {})
    sign_in user
    put action, xhr: true, params: params, format: format, session: session
  end

  # Performs PATCH request as the supplied user for authentication
  def patch_as(user, action, params: {}, format: nil, session: {})
    sign_in user
    patch action, xhr: true, params: params, format: format, session: session
  end

  # Performs DELETE request as the supplied user for authentication
  def delete_as(user, action, params: {}, format: nil, session: {})
    sign_in user
    delete action, xhr: true, params: params, format: format, session: session
  end
end
