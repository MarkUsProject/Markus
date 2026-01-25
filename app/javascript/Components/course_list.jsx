import React from "react";
import {createRoot} from "react-dom/client";
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
    fetch(Routes.courses_path(), {
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

  isPastCourse = course => {
    const endAt = course["courses.end_at"];
    if (!endAt) return false;
    return Date.parse(endAt) < Date.now();
  };

  render() {
    if (this.state.loading == true) {
      return <div></div>;
    } else if (this.state.courses.length == 0) {
      return <div className="no-courses">{I18n.t("courses.no_courses")}</div>;
    }

    const currentCourses = this.state.courses.filter(course => !this.isPastCourse(course));
    const pastCourses = this.state.courses.filter(course => this.isPastCourse(course));
    const isNotStudent = this.state.courses.every(course => course["roles.type"] !== "Student");

    if (isNotStudent) {
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

    // Student View
    return (
      <div className="course-list">
        {currentCourses.length > 0 && (
          <div className="course-group">
            <h2>{I18n.t("courses.current_courses")}</h2>
            <div className="course-current-section">
              {currentCourses.map(course => {
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
          </div>
        )}

        {pastCourses.length > 0 && (
          <div className="course-group">
            <h2>{I18n.t("courses.past_courses")}</h2>
            <div className="course-past-section">
              {pastCourses.map(course => {
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
          </div>
        )}
      </div>
    );
  }
}

export default CourseList;

export function makeCourseList(elem, props) {
  const root = createRoot(elem);
  return root.render(<CourseList {...props} />);
}
