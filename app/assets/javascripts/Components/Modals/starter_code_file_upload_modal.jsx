import React from 'react';
import Modal from 'react-modal';

class StarterCodeFileUploadModal extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      newfiles: [],
      overwrite: true
    }
  }

  componentDidMount() {
    Modal.setAppElement('body');
  }

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit(this.state.newfiles, this.state.overwrite);
  };

  handleFileUpload = (event) => {
    this.setState({newfiles: event.target.files})
  };

  handleOverwriteChange = (event) => {
    this.setState({overwrite: event.target.checked})
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
            <div>
              <label>
                <input
                  type="checkbox"
                  value={this.state.overwrite}
                  checked={this.state.overwrite}
                  name={'overwrite'}
                  onChange={this.handleOverwriteChange}
                /> {I18n.t('assignment.starter_code.overwrite')}
              </label>
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

export default StarterCodeFileUploadModal;
