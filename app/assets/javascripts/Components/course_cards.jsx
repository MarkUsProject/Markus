import React from "react";

class CourseCard extends React.Component {
  onClick = () => {
    window.location += "/" + this.props.course_id;
  };

  render() {
    return (
      <div className="course-card">
        <div className="course-info" onClick={this.onClick}>
          <div className="course-role" align="right">
            {this.props.role_type}
          </div>
          <div className="course-code">{this.props.course_name}</div>
        </div>
        <div className="course-name">
          <a href={window.location + "/" + this.props.course_id}>
            {this.props.course_display_name}
          </a>
        </div>
      </div>
    );
  }
}

export default CourseCard;
