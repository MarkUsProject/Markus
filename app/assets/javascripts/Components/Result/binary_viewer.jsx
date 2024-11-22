import React from "react";

export class BinaryViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {content: null};
    this.abortController = null;
  }

  componentDidMount() {
    // Notify the parent component that the file content is loading.
    this.props.setLoadingCallback(true);

    this.fetchContent(this.props.url)
      .then(content =>
        this.setState({content: content}, () => this.props.setLoadingCallback(false))
      )
      .catch(error => {
        if (error instanceof DOMException) return;
        console.error(error);
      });
  }

  componentDidUpdate(prevProps, prevState) {
    this.props.setLoadingCallback(true);

    if (this.props.url && this.props.url !== prevProps.url) {
      // The URL has updated, so the content needs to be fetched using the new URL.
      this.fetchContent(this.props.url)
        .then(content =>
          this.setState({content: content}, () => this.props.setLoadingCallback(false))
        )
        .catch(error => {
          if (error instanceof DOMException) return;
          console.error(error);
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
      .then(response => {
        if (response.status === 413) {
          const errorMessage = I18n.t("submissions.oversize_submission_file");
          this.props.setErrorMessageCallback(errorMessage);
          throw new Error(errorMessage);
        } else {
          return response.text();
        }
      })
      .then(content => content.replace(/\r?\n/gm, "\n"));
  }

  componentWillUnmount() {
    if (this.abortController) {
      this.abortController.abort();
    }
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
