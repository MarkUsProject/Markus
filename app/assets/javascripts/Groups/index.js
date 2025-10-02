var modalCreate, modalNotesGroup;

(function () {
  const domContentLoadedCB = function () {
    window.modal_rename = new ModalMarkus("#rename_group_dialog");
    modalNotesGroup = new ModalMarkus("#notes_dialog");
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
