import React from "react";

class CourseCard extends React.Component {
  onClick = () => {
    window.location = Routes.course_path(this.props.course_id);
  };

  render() {
    return (
      <div className="course-card" onClick={this.onClick}>
        <div className="course-info">
          <div className="course-role" align="right">
            {this.props.role_type}
          </div>
          <div className="course-code">{this.props.course_name}</div>
        </div>
        <div className="course-name">
          <span>{this.props.course_display_name}</span>
        </div>
      </div>
    );
  }
}

export default CourseCard;
