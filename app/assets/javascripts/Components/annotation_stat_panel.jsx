import React from 'react';
import { render } from 'react-dom';
import ReactDOM from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount() {
    this.fetchData();
  }

  remove_component = (panel) => {
    ReactDOM.unmountComponentAtNode(panel);
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_annotation_categories_path(this.props.annotation_id),
      dataType: 'json'
    }).then(res => {
      this.setState({num_used: res['num_times_used']});
    });
  };

  render() {
    return <fieldset><p>{this.state.num_used}</p></fieldset>;
  }
}


export function makeAnnotationStatPanel(elem, props) {
  return render(<AnnotationStatPanel {...props} />, elem);
}
