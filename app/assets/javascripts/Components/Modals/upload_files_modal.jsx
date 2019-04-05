import React from "react";
import Modal from 'react-modal';

class UploadFilesModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isOpen: props.isOpen || false,
      files: []
    }
  }

  componentWillMount() {
    Modal.setAppElement('body');
  }

  open = () => {
    this.setState({isOpen: true});
  };

  onFileUpload = (event) => {
    this.setState({files: Array.from(event.target.files)})
  };

  onSubmit = () => {
    if (typeof this.props.onSubmit === 'function') {
      this.props.onSubmit(this.state.files);
    }
    this.setState({files: [], isOpen: false})
  };

  onClose = () => {
    this.setState({files: [], isOpen: false})
  };

  render() {
    return (
      <Modal
        onRequestClose={this.onClose}
        {...this.props}
        isOpen={this.state.isOpen}
        className={'dialog'}
      >
        <div>
          <h2>{I18n.t('add_new')}</h2>
          <input type='file' name='new_files[]' multiple={true} onChange={this.onFileUpload}/>
          <section className='dialog-actions'>
            <button onClick={this.onSubmit}>{I18n.t('submit')}</button>
            <button onClick={this.onClose}>{I18n.t('close')}</button>
          </section>
        </div>
      </Modal>
    )
  }
}

export default UploadFilesModal;
