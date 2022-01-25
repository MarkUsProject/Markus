# Groups, Groupings and Repositories

## Assignment Group Models

There are two models that MarkUs supports for managing group membership across multiple assignments in a course.

- Model 1: Assignment groups are independent of one another. Students may freely switch groups from one assignment to the next.
- Model 2: The same group submits work for multiple assignments. For example, a large course project is split across multiple assignments, and the same group submits work for each assignment.

## Groups vs. Groupings

A **grouping** is a set of students who are working together on a single assignment in MarkUs.
A **group** is a collection of groupings, and is used to automatically persist students groups across different assignments if the courses uses "Model 2" above.

Every *group* has an associated repository which stores the files that have been submitted for all of its groupings. Because each repository is associated with a group and not a grouping, one repository may store submitted files for multiple assignments, if the group was persisted across those assignments. This makes it more convenient for students working on a course project split across multiple assignments, as they can keep using the same group repository to store their work.

## Individual Groups

To keep things uniform, MarkUs always associates submitted files with a grouping rather than an individual student, even when that student worked individually for an assignment. It is possible to have a group containing just one student member.

A special case is when the assignment is configured so that students cannot work in groups. In this case, each student is part of a grouping (where they are the only member), but the associated group is the student's "individual group", whose name is the same as the student's username. This means that for all individual assignments, the student groupings are associated with the same individual group, and hence use the same individual repository. Again, this is for the convenience of the student.

For an assignment that allows group work, instructors may still allow students to work individually if they set the assignment's minimum group size to 1. In this case, students have the option of "Working Alone", in which case their grouping will be associated with the individual group and repository, rather than creating a new group.
