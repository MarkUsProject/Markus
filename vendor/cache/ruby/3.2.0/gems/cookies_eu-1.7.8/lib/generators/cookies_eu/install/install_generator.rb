module CookiesEu
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def add_javascripts
        append_file 'app/assets/javascripts/application.js', "//= require cookies_eu\n"
      end

      def add_stylesheets
        file = 'app/assets/stylesheets/application'
        css_file = "#{file}.css"
        scss_file = "#{file}.scss"
        css_scss_file = "#{file}.css.scss"

        if File.exists?(css_file)
          inject_into_file css_file, "*= require cookies_eu\n", before: /\*\//, verbose: true
        elsif File.exists?(scss_file)
          append_file scss_file, "@import 'cookies_eu';\n"
        else
          append_file css_scss_file, "@import 'cookies_eu';\n"
        end
      end
    end
  end
end
