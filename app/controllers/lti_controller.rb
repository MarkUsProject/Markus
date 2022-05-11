class LtiController < ApplicationController
  skip_verify_authorized

  before_action :authenticate, :check_course_switch, :check_record,
                except: [:get_config]

  def get_config
    # See https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # for example configuration and descriptions of fields
    config = {
      title: 'Markus',
      description: 'Markus',
      oidc_initiation_url: "#{root_url}lti/launch",
      target_link_uri: "#{root_url}login",
      scopes: [
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
        'https://purl.imsglobal.org/spec/lti-ags/scope/score',
        'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'
      ],
      extensions: [
        {
          domain: root_url,
          tool_id: 'markus',
          platform: 'canvas.instructure.com',
          privacy_level: 'public',
          settings: {
            text: 'Launch MarkUs',
            placements: [
              {
                text: 'Launch MarkUs',
                placement: 'course_navigation',
                target_link_url: "#{root_url}login",
                canvas_icon_class: 'icon-lti',
                default: 'disabled',
                visibility: 'admins',
                windowTarget: '_blank'
              }
            ]
          }
        }
      ],
      public_jwk_url: "#{root_url}lti/public_jwk"
    }
    render json: config.to_json
  end

  # Define default URL options to not include locale
  def default_url_options(_options = {})
    {}
  end
end
