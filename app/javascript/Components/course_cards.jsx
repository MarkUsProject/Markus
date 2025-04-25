import React from "react";

class CourseCard extends React.Component {
  onClick = () => {
    if (this.props.role_type === "Instructor") {
      window.location = Routes.course_path(this.props.course_id);
    } else {
      window.location = Routes.course_assignments_path(this.props.course_id);
    }
  };

  render() {
    return (
      <div className="course-card" onClick={this.onClick}>
        <div className="course-info">
          <div className="course-role" align="right">
            {I18n.t(`activerecord.models.${this.props.role_type.toLowerCase()}.one`)}
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
