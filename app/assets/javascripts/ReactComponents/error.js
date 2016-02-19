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
    error: React.PropTypes.oneOfType([
      React.PropTypes.string,
      React.PropTypes.array
    ])
  },
  render: function() {
    if (this.props.error) {
      if (typeof(this.props.error) === 'string') {
        return (
          React.DOM.div( {className:'error'}, this.props.error)
        );
      } else if (typeof(this.props.error) === 'object' &&
                 this.props.error.length > 0) { // Array
        errors = this.props.error.map(function(err) {
          return React.DOM.li( { className: 'error' }, err);
        });
        return (
          React.DOM.div(null, errors)
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
