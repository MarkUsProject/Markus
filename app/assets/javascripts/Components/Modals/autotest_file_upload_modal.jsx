import React from 'react';
import Modal from 'react-modal';

class AutotestFileUploadModal extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      newFiles: []
    };
  }

  componentDidMount() {
    Modal.setAppElement('body');
  }

  onSubmit = (event) => {
    event.preventDefault();
    if (!!this.state.newFiles) {
      this.props.onSubmit(this.state.newFiles);
      this.setState({newFiles: []});
    } else {
      this.props.onRequestClose();
    }
  };

  handleFileUpload = (event) => {
    this.setState({newFiles: event.target.files});
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t('upload')}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={'modal-container-vertical'}>
            <div className={'modal-container'}>
              <input type={'file'} name={'new_files'} multiple={true} onChange={this.handleFileUpload}/>
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

export default AutotestFileUploadModal;
