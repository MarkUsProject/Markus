document.addEventListener("DOMContentLoaded", function () {
  console.log("Subscriber initialized");
  const consumer = ActionCable.createConsumer();
  const courseId = document.getElementById("course-data").dataset.courseId;

  consumer.subscriptions.create(
    {channel: "ExamTemplatesChannel", course_id: courseId},
    {
      received(data) {
        if (data.status === "started") {
          console.log("Job started");
        } else if (data.status === "in progress") {
          console.log("Job in progress");
        } else if (data.status === "completed") {
          console.log("Job completed");
        } else if (data.status === "failed") {
          console.log("Job failed");
        }
      },
      connected() {
        console.log("Connected to ExamTemplatesChannel");
      },
      disconnected() {
        console.log("Disconnected from ExamTemplatesChannel");
      },
    }
  );
});
