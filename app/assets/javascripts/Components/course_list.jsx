import React from "react";
import {render} from "react-dom";
import CourseCard from "./course_cards";

class CourseList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      courses: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.courses_url(), {
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(response => {
        this.setState({
          courses: response.data,
          loading: false,
        });
      });
  };

  render() {
    if (this.state.loading == true) {
      return <div></div>;
    } else if (this.state.courses.length == 0) {
      return <div className="no-courses">{I18n.t("courses.no_courses")}</div>;
    }
    return (
      <div className="course-list">
        {this.state.courses.map(course => {
          return (
            <CourseCard
              key={course["courses.id"]}
              course_id={course["courses.id"]}
              course_name={course["courses.name"]}
              course_display_name={course["courses.display_name"]}
              role_type={course["roles.type"]}
            />
          );
        })}
      </div>
    );
  }
}

export function makeCourseList(elem, props) {
  return render(<CourseList {...props} />, elem);
}
