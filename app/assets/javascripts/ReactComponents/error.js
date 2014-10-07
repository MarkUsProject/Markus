/** @jsx React.DOM */

/* Component that represents the error div commonly
 * seen on MarkUs pages. It takes only one prop, 
 * which is the error string. If the string is empty
 * (or null), the div doesn't show anything, but otherwise
 * it returns a div with class 'error', which is style
 * according to the CSS.
 */
 var ErrorDiv = React.createClass({displayName: 'ErrorDiv',
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
