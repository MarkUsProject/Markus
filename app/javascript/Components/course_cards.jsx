import React from "react";

class CourseCard extends React.Component {
  coursePath = () => {
    if (this.props.role_type === "Instructor") {
      return Routes.course_path(this.props.course_id);
    }
    return Routes.course_assignments_path(this.props.course_id);
  };

  render() {
    return (
      <a className="course-card" href={this.coursePath()}>
        <div className="course-info">
          <div className="course-role" align="right">
            {I18n.t(`activerecord.models.${this.props.role_type.toLowerCase()}.one`)}
          </div>
          <div className="course-code">{this.props.course_name}</div>
        </div>
        <div className="course-name">
          <span>{this.props.course_display_name}</span>
        </div>
      </a>
    );
  }
}

export default CourseCard;
