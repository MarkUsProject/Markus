# Configuration for the 'responders' gem

Rails.application.config.app_generators.scaffold_controller :responders_controller
Responders::FlashResponder.flash_keys = [:success, :error]
