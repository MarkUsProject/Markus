import React from "react";
import Modal from "react-modal";

class FilterModal extends React.Component {
  static defaultProps = {};

  constructor(props) {
    super(props);
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onRequestClose();
  };

  render() {
    return (
      <div>
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.onRequestClose}
        >
          <h2>{"Filter By:"}</h2>
          <form onSubmit={this.onSubmit}>
            <div>
              <section className={"modal-container dialog-actions"}>
                <input type="submit" value={"Save"} />
              </section>
            </div>
          </form>
        </Modal>
      </div>
    );
  }
}

export default FilterModal;
