/**
 * Function for getting the status of a background task.
 * Polls the JobMessages controller for the status of a job.
 *
 * Note that the controller uses flash messages to display progress
 * to the user.
 */

export function poll_job(job_id, onSuccess, onFailure, onComplete, interval) {
  interval = interval || 1000;
  $.ajax({
    url: Routes.get_job_message_path(job_id),
    success: function (data) {
      if (data.status === "completed") {
        if (onSuccess) {
          onSuccess(data);
        }
        if (onComplete) {
          onComplete(data);
        }
      } else if (data.status === "failed") {
        if (onFailure) {
          onFailure(data);
        }
        if (onComplete) {
          onComplete(data);
        }
      } else {
        window.setTimeout(function () {
          poll_job(job_id, onSuccess, onComplete);
        }, interval);
      }
    },
  });
}
