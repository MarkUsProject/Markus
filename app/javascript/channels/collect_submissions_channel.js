import consumer from "./consumer";

function create_collect_submissions_channel_subscription() {
  consumer.subscriptions.create("CollectSubmissionsChannel", {
    connected() {
      // Called when the subscription is ready for use on the server
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(data) {
      // Called when there's incoming data on the websocket for this channel
      window.submissionTable.wrapped.fetchData();

    },
  });
}
export {create_collect_submissions_channel_subscription};
