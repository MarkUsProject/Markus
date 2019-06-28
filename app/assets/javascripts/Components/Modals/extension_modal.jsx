import React from 'react';
import Modal from 'react-modal';


class ExtensionModal extends React.Component {

  static defaultProps = {
    weeks: 0,
    days: 0,
    hours: 0,
    note: '',
    penalty: false,
    updating: false
  };

  constructor(props) {
    super(props);
    this.state = {
      weeks: props.weeks,
      days: props.days,
      hours: props.hours,
      note: props.note,
      penalty: props.penalty
    };
  }

  componentDidMount() {
    Modal.setAppElement('body');
  }

  stateHasChanged = () => {
    for (let s of Object.keys(this.state)) {
      if (this.state[s] !== this.props[s]) {
        return true
      }
    }
    return false
  };

  submitForm = (event) => {
    event.preventDefault();
    if (this.stateHasChanged()) {
      let data = {
        weeks: this.state.weeks,
        days: this.state.days,
        hours: this.state.hours,
        note: this.state.note,
        penalty: this.state.penalty,
        grouping_id: this.props.grouping_id
      };
      if (!!this.props.extension_id) {
        $.ajax({
          type: "PUT",
          url: Routes.extension_path(this.props.extension_id),
          data: data
        }).then(() => this.props.onRequestClose(true));
      } else {
        $.post({
          url: Routes.extensions_path(),
          data: data
        }).then(() => this.props.onRequestClose(true));
      }
    } else {
      this.props.onRequestClose(false)
    }
  };

  deleteExtension = (event) => {
    event.preventDefault();
    $.ajax({
      type: "DELETE",
      url: Routes.extension_path(this.props.extension_id)
    }).then(() => this.props.onRequestClose(true));
  };

  handleModalInputChange = (event) => {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;

    this.setState({
      [name]: value
    });
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("activerecord.models.extensions.one")}</h2>
        <form onSubmit={this.submitForm}>
          <div className={'modal-container-vertical'}>
            <div className={'modal-container'}>
              <label>
                <input
                  type="number"
                  value={this.state.weeks}
                  max={999}
                  min={0}
                  name={'weeks'}
                  onChange={this.handleModalInputChange}
                /> {I18n.t('extensions.weeks')}
              </label>
              <label>
                <input
                  type="number"
                  value={this.state.days}
                  max={999}
                  min={0}
                  name={'days'}
                  onChange={this.handleModalInputChange}
                /> {I18n.t('extensions.days')}
              </label>
              <label>
                <input
                  type="number"
                  value={this.state.hours}
                  max={999}
                  min={0}
                  name={'hours'}
                  onChange={this.handleModalInputChange}
                /> {I18n.t('extensions.hours')}
              </label>
            </div>
            <br/>
            <div>
              <label>
                <input
                  type="checkbox"
                  value={this.state.penalty}
                  checked={this.state.penalty}
                  name={'penalty'}
                  onChange={this.handleModalInputChange}
                /> {I18n.t('extensions.apply_penalty')}
              </label>
            </div>
            <div>
              <label>
                <textarea
                  className={'extension-note'}
                  placeholder={I18n.t('activerecord.attributes.extensions.note') + '...'}
                  value={this.state.note}
                  name={'note'}
                  onChange={this.handleModalInputChange}
                />
              </label>
            </div>
            <div className={"modal-container"}>
              <input type="submit" value={I18n.t("save")} />
              <button
                onClick={this.deleteExtension}
                disabled={!this.props.updating}
              >
                {I18n.t("delete")}
              </button>
            </div>
          </div>
        </form>
      </Modal>
    )
  }
}

export default ExtensionModal;
