var modalCreate,
  modalNotesGroup,
  modalAssignmentGroupReUse = null;

(function () {
  const domContentLoadedCB = function () {
    modalCreate = new ModalMarkus("#create_group_dialog");
    modalNotesGroup = new ModalMarkus("#notes_dialog");
    modalAssignmentGroupReUse = new ModalMarkus("#assignment_group_use_dialog");
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
