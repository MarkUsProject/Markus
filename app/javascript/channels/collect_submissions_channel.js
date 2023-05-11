import consumer from "./consumer"

function create_collect_submissions_channel_subscription(){
  consumer.subscriptions.create("CollectSubmissionsChannel", {
    connected() {
      // Called when the subscription is ready for use on the server
      console.log("Connected");
    },

    disconnected() {
      console.log("Disconnected");
      // Called when the subscription has been terminated by the server
    },

    received(data) {
      console.log(data["body"]);
      console.log("received data");
      window.submissionTable.wrapped.fetchData();
      console.log("did the fetch data thing");
      // Called when there's incoming data on the websocket for this channel
    }
  });
}
export {create_collect_submissions_channel_subscription}
