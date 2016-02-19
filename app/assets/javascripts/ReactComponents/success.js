/** @jsx React.DOM */

/* Component that represents the success div commonly
 * seen on MarkUs pages. It takes only one prop, 
 * which is the success string. If the string is empty
 * (or null), the div doesn't show anything, but otherwise
 * it returns a div with class 'success', which is style
 * according to the CSS.
 */
 var SuccessDiv = React.createClass({displayName: 'SuccessDiv',
  propTypes: {
    success: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.array
    ])
  },
  render: function() {
    if (this.props.success) {
      if (typeof(this.props.success) === 'string') {
        return (
          React.DOM.div( {className:'success'}, this.props.success)
        );
      } else if (typeof(this.props.success) === 'object' &&
                 this.props.success.length > 0) { // Array
        successs = this.props.success.map(function(err) {
          return React.DOM.div( { className: 'success' }, err);
        });
        return (
          React.DOM.div(null, successs)
        );
      } else {
        return (
          React.DOM.div(null)
        );
      }
    }
    else {
      return (
        React.DOM.div(null)
      );
    }
  }
});
