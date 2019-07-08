import React from 'react';
import Modal from 'react-modal';

class CollectSubmissionsModal extends React.Component {

  static defaultProps = {
    override: false
  };

  constructor(props) {
    super(props);
    this.state = {
      override: this.props.override
    };
  }

  componentDidMount() {
    Modal.setAppElement('body');
  }

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit(this.state.override);
  };

  handleOverrideChange = (event) => {
    this.setState({override: event.target.checked})
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>
          {I18n.t('submissions.collect.submit')}
        </h2>
        <form onSubmit={this.onSubmit}>
          <div className={'modal-container-vertical'}>
            <div>
              {I18n.t('submissions.collect.results_loss_warning')}
            </div>
            <div>
              <label>
                <input type="checkbox" name="override" onChange={this.handleOverrideChange}/>
                &nbsp; {I18n.t('submissions.collect.override_existing')}
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

export default CollectSubmissionsModal;
