import React from 'react';
import Modal from 'react-modal';

class SubmissionFileUploadModal extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      newfiles: []
    }
  }

  componentDidMount() {
    Modal.setAppElement('body');
  }

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit(this.state.newfiles);
  };

  handleFileUpload = (event) => {
    this.setState({newfiles: event.target.files})
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t('add_new')}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={'modal-container-vertical'}>
            <div className={'modal-container'}>
              <input type={'file'} name={'newfiles'} multiple={true} onChange={this.handleFileUpload}/>
            </div>
            <div className={'modal-container'}>
              <input type='submit' value={I18n.t('save')} />
            </div>
          </div>
        </form>
      </Modal>
    )
  }
}

export default SubmissionFileUploadModal;
