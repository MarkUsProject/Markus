export function refreshOrLogout() {
  $.ajax({url: Routes.refresh_session_main_index_path(), method: "POST"});
}
