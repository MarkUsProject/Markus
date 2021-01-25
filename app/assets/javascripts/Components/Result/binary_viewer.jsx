import React from 'react';

export class BinaryViewer extends React.Component {
  render() {
    return <div>
      <p>{this.props.content}</p>
      <a onClick={this.props.getAnyway}>{I18n.t('submissions.get_anyway')}</a>
    </div>
  }
}
