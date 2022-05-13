class LtiController < ApplicationController
  skip_verify_authorized

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_canvas_config]

  def get_canvas_config
    # See https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # for example configuration and descriptions of fields
    config = {
      title: I18n.t('markus'),
      description: I18n.t('markus'),
      oidc_initiation_url: launch_lti_index_url,
      target_link_uri: root_url,
      scopes: [],
      extensions: [
        {
          domain: request.domain(3),
          tool_id: I18n.t('markus'),
          platform: 'canvas.instructure.com',
          privacy_level: 'public',
          settings: {
            text: I18n.t('lti.launch'),
            placements: [
              {
                text: I18n.t('lti.launch'),
                placement: 'course_navigation',
                target_link_uri: root_url,
                canvas_icon_class: 'icon-lti',
                default: 'disabled',
                visibility: 'admins',
                windowTarget: '_blank'
              }
            ]
          }
        }
      ],
      public_jwk_url: public_jwk_lti_index_url
    }
    render json: config.to_json
  end

  def launch
    # TODO: implement this function
    render json: { state: 'success' }
  end

  def public_jwk
    # TODO: implement this function
    render json: { state: 'success' }
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
