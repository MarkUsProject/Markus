import React from "react";
import {render} from "react-dom";
import CourseCard from "./course_cards";

class CourseList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      courses: [],
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      method: "get",
      url: Routes.courses_path(),
      dataType: "json",
    }).then(res =>
      this.setState({
        courses: res.data,
      })
    );
  };

  makeCourseCards() {}

  render() {
    console.log(this.state);
    if (this.state.courses.length == 0) {
      return <div className="no course"></div>;
    }
    return (
      <div>
        {this.state.courses.map(course => {
          console.log(course);
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
