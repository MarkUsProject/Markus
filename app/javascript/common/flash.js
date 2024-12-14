const FLASH_KEYS = ["notice", "warning", "success", "error"];

const generateFlashMessageContentsUsingStatus = status_data => {
  let message_data = {};
  switch (status_data["status"]) {
    case "failed":
      if (!status_data["exception"] || !status_data["exception"]["message"]) {
        message_data["error"] = I18n.t("job.status.failed.no_message");
      } else {
        message_data["error"] = I18n.t("job.status.failed.message", {
          error: status_data["exception"]["message"],
        });
      }
      break;
    case "completed":
      message_data["success"] = I18n.t("job.status.completed");
      break;
    case "queued":
      message_data["notice"] = I18n.t("job.status.queued");
      break;
    default:
      let progress = status_data["progress"];
      let total = status_data["total"];
      message_data["notice"] = I18n.t("submissions.collect.status.in_progress", {progress, total});
  }
  if (status_data["warning_message"]) {
    message_data["warning"] = status_data["warning_message"];
  }
  return message_data;
};

const renderFlashMessages = message_data => {
  hideFlashMessages();
  FLASH_KEYS.forEach(key => {
    let message = message_data[key];
    if (message) {
      flashMessage(message, key);
    }
  });
};

const flashMessage = (message, key) => {
  message = `<p>${message.replaceAll("\n", "<br/>")}</p>`;
  const flashDiv = document.getElementsByClassName(key)[0];
  const contents = flashDiv.getElementsByClassName("flash-content")[0] || flashDiv;
  contents.innerHTML = "";
  contents.insertAdjacentHTML("beforeend", message);
  flashDiv.style.display = "block";
};

const hideFlashMessages = () => {
  FLASH_KEYS.forEach(key => {
    for (let elem of document.getElementsByClassName(key)) {
      elem.style.display = "none";
      const contents = elem.getElementsByClassName("flash-content")[0] || elem;
      contents.innerHTML = "";
    }
  });
};

export {
  FLASH_KEYS,
  generateFlashMessageContentsUsingStatus,
  renderFlashMessages,
  hideFlashMessages,
  flashMessage,
};
