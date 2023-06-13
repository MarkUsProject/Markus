document.addEventListener("DOMContentLoaded", () => {
  setInterval(() => {
    $.get(Routes.check_timeout_main_index_path());
  }, 120000);
});
