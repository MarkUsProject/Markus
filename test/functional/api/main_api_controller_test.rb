require File.join(File.dirname(__FILE__),'..', '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'blueprints')
require File.join(File.dirname(__FILE__), '..', '..', 'blueprints', 'helper')
require 'shoulda'
require 'base64'

# Tests the authentication mechanism of the MarkUs API
class Api::MainApiControllerTest < ActionController::TestCase

  context 'An unauthenticated GET request on any API controller' do
    setup do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      @res = get('index')
    end

    should respond_with :forbidden

    should 'receive a 403 response' do
      assert_not_nil(@res.body =~ /<title>403 Forbidden<\/title>/)
    end
  end

  context 'An unauthenticated PUT request on any API controller' do
    setup do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      @res = put('index')
    end

    should respond_with :forbidden

    should 'receive a 403 response' do
      assert_not_nil(@res.body  =~ /<title>403 Forbidden<\/title>/)
    end
  end

  context 'An unauthenticated DELETE request on any API controller' do
    setup do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      @res = delete('index')
    end

    should respond_with :forbidden

    should 'receive a 403 response' do
      assert_not_nil(@res.body  =~ /<title>403 Forbidden<\/title>/)
    end
  end

  context 'An unauthenticated POST request on any API controller' do
    setup do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      @res = post('index')
    end

    should respond_with :forbidden

    should 'receive a 403 response' do
      assert_not_nil(@res.body  =~ /<title>403 Forbidden<\/title>/)
    end
  end

  # Tests authenticated requests to the API controllers
  context 'Authenticated request to any API controller' do
    setup do
      admin = Admin.make
      base_encoded_md5 = admin.api_key.strip
      auth_http_header = "MarkUsAuth #{base_encoded_md5}"
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      @request.env['HTTP_AUTHORIZATION'] = auth_http_header
    end

    context 'An authenticated GET request to any API controller' do
      setup do
        @res = get('index')
      end

      should 'render a 404 response by default' do
        assert render_template 'shared/http_status'
        assert_not_nil(@res.body  =~ /#{HttpStatusHelper::ERROR_CODE['message']['404']}/)
      end
    end

    context 'An authenticated PUT request to any API controller' do
      setup do
        @res = put('index')
      end

      should 'render a 404 response by default' do
        assert render_template 'shared/http_status'
        assert_not_nil(@res.body  =~ /#{HttpStatusHelper::ERROR_CODE['message']['404']}/)
      end
    end

    context 'An authenticated DELETE request to any API controller' do
      setup do
        @res = delete('index')
      end

      should 'render a 404 response by default' do
        assert render_template 'shared/http_status'
        assert_not_nil(@res.body  =~ /#{HttpStatusHelper::ERROR_CODE['message']['404']}/)
      end
    end

    context 'An authenticated POST request to any API controller' do
      setup do
        @res = post('index')
      end

      should 'render a 404 response by default' do
        assert render_template 'shared/http_status'
        assert_not_nil(@res.body  =~ /#{HttpStatusHelper::ERROR_CODE['message']['404']}/)
      end
    end
  end

end
