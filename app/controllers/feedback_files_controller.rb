class FeedbackFilesController < ApplicationController
  include DownloadHelper

  before_action { authorize! }

  def get_feedback_file
    feedback_file = FeedbackFile.find(params[:id])
    send_data_download feedback_file.file_content, filename: feedback_file.filename
  end
end
