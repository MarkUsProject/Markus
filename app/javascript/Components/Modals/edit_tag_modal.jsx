import {useEffect, useState} from "react";
import Modal from "react-modal";
import TagModal from "../Helpers/tag_modal";
import PropTypes from "prop-types";

export default function EditTagModal({
  course_id,
  currentTagDescription,
  currentTagName,
  isOpen,
  onRequestClose,
  tag_id,
}) {
  const [name, setName] = useState(currentTagName);
  const [description, setDescription] = useState(currentTagDescription);

  useEffect(() => {
    Modal.setAppElement("body");
  }, []);

  const onSubmit = event => {
    event.preventDefault();
    const data = {
      tag: {
        name,
        description,
      },
      course_id,
      id: tag_id,
      submit: "Save",
    };
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify(data),
    };
    fetch(Routes.course_tag_path(course_id, tag_id), options)
      .then(() => {
        onRequestClose();
      })
      .catch(error => {
        console.error(error.message);
      });
  };

  return (
    <TagModal
      name={name}
      description={description}
      handleNameChange={event => setName(event.target.value)}
      handleDescriptionChange={event => setDescription(event.target.value)}
      isOpen={isOpen}
      onRequestClose={onRequestClose}
      tagModalHeading={I18n.t("helpers.submit.update", {
        model: I18n.t("activerecord.models.tag.one"),
      })}
      onSubmit={onSubmit}
    />
  );
}

EditTagModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  tag_id: PropTypes.number.isRequired,
  course_id: PropTypes.number.isRequired,
  assignment_id: PropTypes.number.isRequired,
  currentTagName: PropTypes.string.isRequired,
  currentTagDescription: PropTypes.string.isRequired,
};
