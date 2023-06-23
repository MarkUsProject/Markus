(function () {
  const domContentLoadedCB = () => {
    window.role_switch_modal = new ModalMarkus("#role_switch_dialog");
    window.about_modal = new ModalMarkus("#about_dialog");
    window.timeout_imminent_modal = new ModalMarkus("#timeout_imminent_dialog");
    window.session_expired_modal = new ModalMarkus("#session_expired_dialog");
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
})();
