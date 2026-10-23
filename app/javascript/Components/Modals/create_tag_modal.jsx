import {useContext, useEffect, useState} from "react";
import TagModal from "../Helpers/tag_modal";
import Modal from "react-modal";
import PropTypes from "prop-types";
import {ResultContext} from "../Result/result_context";

export default function CreateTagModal({isOpen, onRequestClose}) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const context = useContext(ResultContext);

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
      grouping_id: context.grouping_id,
    };
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify(data),
    };
    fetch(
      Routes.course_tags_path(context.course_id, {assignment_id: context.assignment_id}),
      options
    )
      .catch(error => {
        console.error(`Error submitting form: ${error.message}`);
      })
      .finally(() => {
        setName("");
        setDescription("");
        onRequestClose();
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
      tagModalHeading={I18n.t("helpers.submit.create", {
        model: I18n.t("activerecord.models.tag.one"),
      })}
      onSubmit={onSubmit}
    />
  );
}

CreateTagModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
};
