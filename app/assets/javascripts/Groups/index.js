var modalCreate, modalNotesGroup;

(function () {
  const domContentLoadedCB = function () {
    modalNotesGroup = new ModalMarkus("#notes_dialog");
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
