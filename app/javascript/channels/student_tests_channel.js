import consumer from "./consumer";

// Parameter: fetchData method provided by TestRunTable component
function create_student_tests_channel_subscription(table) {
  consumer.subscriptions.create(
    {
      channel: "StudentTestsChannel",
      course_id: table.props.course_id,
      assignment_id: table.props.assignment_id,
      grouping_id: table.props.grouping_id,
    },
    {
      connected() {
        // Called when the subscription is ready for use on the server
        console.log("Connected");
      },

      disconnected() {
        // Called when the subscription has been terminated by the server
        console.log("Disconnected");
      },

      received(data) {
        console.log("Got it");
        table.fetchData();
        // Called when there's incoming data on the websocket for this channel
        console.log("Data: " + data["body"]);
      },
    }
  );
}
export {create_student_tests_channel_subscription};
