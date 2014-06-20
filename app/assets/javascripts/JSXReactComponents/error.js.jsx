/** @jsx React.DOM */

Error = React.createClass({
  propTypes: {
    error: React.PropTypes.string
  },
  render: function() {
    if (this.props.error) {
      return (
        <div className={'error'}>{this.props.error}</div>
      );
    }
    else {
      return (
        <div></div>
      );
    }
  }
});

