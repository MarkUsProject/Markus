import React from "react";

export class BinaryViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {content: null};
    this.controller = new AbortController();
    this.signal = this.controller.signal;
    this.mountedRef = React.createRef();
    this.abortController = null;
  }

  componentDidMount() {
    this.mountedRef.current = true;
    // Notify the parent component that the file content is loading.
    this.props.setLoadingCallback(true);

    this.fetchContent(this.props.url).then(content => {
      if (this.mountedRef.current) {
        this.setState({content: content}, () => this.props.setLoadingCallback(false));
      }
    });
  }

  componentDidUpdate(prevProps, prevState) {
    this.props.setLoadingCallback(true);

    if (this.props.url && this.props.url !== prevProps.url) {
      // The URL has updated, so the content needs to be fetched using the new URL.
      this.fetchContent(this.props.url).then(content => {
        if (this.mountedRef.current) {
          this.setState({content: content}, () => this.props.setLoadingCallback(false));
        }
      });
    }
  }

  fetchContent(url) {
    if (this.abortController) {
      // Stops ongoing fetch requests. It's ok to call .abort() after the fetch has already completed,
      // fetch simply ignores it.
      this.abortController.abort();
    }
    // Reinitialize the controller, because the signal can't be reused after the request has been aborted.
    this.abortController = new AbortController();

    return fetch(url, {signal: this.abortController.signal})
      .then(response => response.text())
      .then(content => content.replace(/\r?\n/gm, "\n"))
      .catch(error => console.error(error));
  }

  componentWillUnmount() {
    if (this.abortController) {
      this.controller.abort();
    }
    this.mountedRef.current = false;
  }

  render() {
    return (
      <div>
        <p>{this.props.content}</p>
        <a onClick={this.props.getAnyway}>{I18n.t("submissions.get_anyway")}</a>
      </div>
    );
  }
}
