import React from "react";
import {render} from "react-dom";

export class CourseCard extends React.Component {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <div className="course_card">
        {/*<a href={Routes.browse_courses(this.props.course_id)}></a>*/}
        <div className="course_code" id="course_code">
          <span>{this.props.course_name}</span>
          <span>{this.props.role_type}</span>
        </div>
        <div id="course_name">
          <span>{this.props.course_display_name}</span>
        </div>
      </div>
    );
  }
}

export function makeCourseCard(elem, props) {
  return render(<CourseCard {...props} />, elem);
}
export default CourseCard;
