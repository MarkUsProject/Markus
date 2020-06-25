import React from 'react';
import { render } from 'react-dom';
import ReactDOM from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {}
  }

  componentDidMount() {
    this.fetchData();
  }

  remove_component = (panel) => {
    ReactDOM.unmountComponentAtNode(panel);
  }

  fetchData = () => {
    $.ajax({
      url: Routes.get_annotation_text_stats_assignment_annotation_categories_path(
        this.props.assignment_id,
        this.props.annotation_category
      ),
      data: {
        annotation_text_id: this.state.annotation_id
      },
      dataType: 'json'
    }).then(res => {
      console.log(res)
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
