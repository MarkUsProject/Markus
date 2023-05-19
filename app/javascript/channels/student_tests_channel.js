import consumer from "./consumer";

// Parameter: fetchData method provided by TestRunTable component
function create_student_tests_channel_subscription(fetchData) {
  consumer.subscriptions.create("StudentTestsChannel", {
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
      fetchData();
      // Called when there's incoming data on the websocket for this channel
      console.log("Data: " + data["body"]);
    },
  });
}
export {create_student_tests_channel_subscription};
