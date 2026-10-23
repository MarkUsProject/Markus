import {useEffect, useRef, useState} from "react";
import Modal from "react-modal";

export default function RenameGroupModal({initialGroupName, isOpen, onRequestClose, onSubmit}) {
  const [groupName, setGroupName] = useState(initialGroupName || "");
  const previousIsOpen = useRef(isOpen);

  useEffect(() => {
    Modal.setAppElement("body");
  }, []);

  useEffect(() => {
    if (isOpen && !previousIsOpen.current && initialGroupName) {
      setGroupName(initialGroupName);
    }
    previousIsOpen.current = isOpen;
  }, [initialGroupName, isOpen]);

  const handleChange = event => {
    setGroupName(event.target.value);
  };

  const handleSubmit = event => {
    event.preventDefault();
    if (!groupName) {
      return;
    }
    onSubmit(groupName);
    setGroupName("");
  };

  return (
    <Modal
      className="react-modal markus-dialog"
      isOpen={isOpen}
      onRequestClose={onRequestClose}
      id="rename_group_dialog"
    >
      <h2>{I18n.t("groups.rename_group")}</h2>
      <form onSubmit={handleSubmit}>
        <label htmlFor="groupName">{I18n.t("activerecord.attributes.group.group_name")}</label>
        <input id="groupName" type="text" value={groupName} onChange={handleChange} autoFocus />
        <div className={"dialog-actions"}>
          <button
            className="button"
            type="submit"
            disabled={!groupName}
            data-testid="rename-submit-button"
          >
            {I18n.t("groups.rename_group")}
          </button>
          <button className="button" type="reset" onClick={onRequestClose}>
            {I18n.t("cancel")}
          </button>
        </div>
      </form>
    </Modal>
  );
}
