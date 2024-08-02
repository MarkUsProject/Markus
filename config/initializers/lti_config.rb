if Settings.lti.course_filter_file.present?
  # config.to_prepare is used so that the block is executed on reloads.
  # See https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoload-on-boot-and-on-each-reload
  Rails.application.config.to_prepare do
    load Settings.lti.course_filter_file
  end
end
