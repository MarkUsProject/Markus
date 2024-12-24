# Controller for downloading individual feedback files by id
class FeedbackFilesController < ApplicationController
  include DownloadHelper

  before_action { authorize! }

  def show
    feedback_file = record
    send_data_download feedback_file.file_content, filename: feedback_file.filename
  end
end
