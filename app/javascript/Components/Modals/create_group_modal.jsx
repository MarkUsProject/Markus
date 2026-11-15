import {useEffect, useState} from "react";
import Modal from "react-modal";

export default function CreateGroupModal({isOpen, onRequestClose, onSubmit}) {
  const [groupName, setGroupName] = useState("");

  useEffect(() => {
    Modal.setAppElement("body");
  }, []);

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
      id="create_group_modal"
    >
      <h2>{I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})}</h2>
      <form onSubmit={handleSubmit}>
        <label htmlFor="groupName">{I18n.t("activerecord.models.group.one")}</label>
        <input id="groupName" type="text" value={groupName} onChange={handleChange} autoFocus />
        <div className={"dialog-actions"}>
          <button className="button" type="submit" disabled={!groupName}>
            {I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})}
          </button>
          <button className="button" type="reset" onClick={onRequestClose}>
            {I18n.t("cancel")}
          </button>
        </div>
      </form>
    </Modal>
  );
}
