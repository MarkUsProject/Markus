(function () {
  const domContentLoadedCB = function () {
    window.modal_add_section = new ModalMarkus("#add_new_section_dialog");
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
