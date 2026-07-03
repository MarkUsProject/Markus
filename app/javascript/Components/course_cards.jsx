function CourseCard({course_id, course_name, course_display_name, role_type}) {
  let coursePath;
  if (role_type === "Instructor") {
    coursePath = Routes.course_path(course_id);
  } else {
    coursePath = Routes.course_assignments_path(course_id);
  }

  return (
    <a className="course-card" href={coursePath}>
      <div className="course-info">
        <div className="course-role" align="right">
          {I18n.t(`activerecord.models.${role_type.toLowerCase()}.one`)}
        </div>
        <div className="course-code">{course_name}</div>
      </div>
      <div className="course-name">
        <span>{course_display_name}</span>
      </div>
    </a>
  );
}

export default CourseCard;
