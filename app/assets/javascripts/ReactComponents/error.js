/** @jsx React.DOM */

Error = React.createClass({displayName: 'Error',
  propTypes: {
    error: React.PropTypes.string
  },
  render: function() {
    if (this.props.error) {
      return (
        React.DOM.div( {className:'error'}, this.props.error)
      );
    }
    else {
      return (
        React.DOM.div(null)
      );
    }
  }
});
