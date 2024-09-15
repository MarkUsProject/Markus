# frozen_string_literal: true

# Licensed to the Software Freedom Conservancy (SFC) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The SFC licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'selenium/webdriver/chromium/features'

module Selenium
  module WebDriver
    module Chrome
      module Features
        include WebDriver::Chromium::Features

        CHROME_COMMANDS = {
          get_cast_sinks: [:get, 'session/:session_id/goog/cast/get_sinks'],
          set_cast_sink_to_use: [:post, 'session/:session_id/goog/cast/set_sink_to_use'],
          start_cast_tab_mirroring: [:post, 'session/:session_id/goog/cast/start_tab_mirroring'],
          start_cast_desktop_mirroring: [:post, 'session/:session_id/goog/cast/start_desktop_mirroring'],
          get_cast_issue_message: [:get, 'session/:session_id/goog/cast/get_issue_message'],
          stop_casting: [:post, 'session/:session_id/goog/cast/stop_casting'],
          send_command: [:post, 'session/:session_id/goog/cdp/execute']
        }.freeze

        def command_list
          CHROME_COMMANDS.merge(CHROMIUM_COMMANDS).merge(self.class::COMMANDS)
        end

        def commands(command)
          command_list[command]
        end
      end # Bridge
    end # Chrome
  end # WebDriver
end # Selenium
