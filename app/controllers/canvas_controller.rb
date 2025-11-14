class CanvasController < LtiDeploymentsController
  LMS_REDIRECT_ENDPOINT = '/api/lti/authorize_redirect'.freeze
  LMS_JWK_ENDPOINT = '/api/lti/security/jwks'.freeze

  def get_config
    # See https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
    # for example configuration and descriptions of fields
    config = {
      title: I18n.t('markus'),
      description: I18n.t('markus'),
      oidc_initiation_url: launch_canvas_url,
      target_link_uri: redirect_login_canvas_url,
      scopes: [LtiDeployment::LTI_SCOPES[:names_role],
               LtiDeployment::LTI_SCOPES[:ags_lineitem],
               LtiDeployment::LTI_SCOPES[:score],
               LtiDeployment::LTI_SCOPES[:results]],
      extensions: [
        {
          domain: request.domain(3),
          tool_id: I18n.t('markus'),
          platform: 'canvas.instructure.com',
          privacy_level: 'public', # Include user name information
          settings: {
            text: I18n.t('lti.launch'),
            placements: [
              {
                text: I18n.t('lti.launch'),
                placement: 'course_navigation',
                canvas_icon_class: 'icon-lti',
                default: 'disabled',
                visibility: 'admins',
                windowTarget: '_blank'
              }
            ]
          }
        }
      ],
      public_jwk_url: public_jwk_lti_deployments_url,
      custom_fields: {
        user_id: '$Canvas.user.id',
        course_id: '$Canvas.course.id',
        course_name: '$Canvas.course.name',
        student_number: '$Canvas.user.sisIntegrationId'
      }
    }

    render json: config.to_json
  end
end
