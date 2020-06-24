import React from 'react';
import { render } from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    console.log('stuff happening')
    return
    // $.get({
    //   url: Routes.assignment_submission_result_path(
    //     this.props.assignment_id,
    //     this.props.submission_id,
    //     this.props.result_id
    //   ),
    //   dataType: 'json'
    // }).then(res => {
    //   if (res.submission_files) {
    //     res.submission_files = this.processSubmissionFiles(res.submission_files);
    //   }
    //   const markData = this.processMarks(res);
    //   this.setState({...res, ...markData, loading: false}, () => {
    //     initializePanes();
    //     fix_panes();
    //     this.updateContextMenu();
    //   });
    // });
  };

  render() {
    return;
  }
}


export function makeAnnotationStatPanel(elem, props) {
  console.log('this is running');
  console.log(document);
  console.log(elem)
  console.log(props)
  return render(<AnnotationStatPanel {...props} />, elem);
}
