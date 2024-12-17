import React from "react";

export class BinaryViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      content: null,
      getAnyway: false,
    };
    this.abortController = null;
  }

  componentDidMount() {
    // Notify the parent component that the file content is loading.
    this.props.setLoadingCallback(true);
    // The URL has updated, so the content needs to be fetched using the new URL.
    this.fetchContent(this.props.url)
      .then(content =>
        this.setState({content: content}, () => this.props.setLoadingCallback(false))
      )
      .catch(error => {
        this.props.setLoadingCallback(false);
        if (error instanceof DOMException) return;
        console.error(error);
      });
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.url && this.props.url !== prevProps.url) {
      this.setState({getAnyway: false});
      this.props.setLoadingCallback(true);
      this.fetchContent(this.props.url)
        .then(content =>
          this.setState({content: content}, () => this.props.setLoadingCallback(false))
        )
        .catch(error => {
          this.props.setLoadingCallback(false);
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
        {!this.state.getAnyway && (
          <a onClick={() => this.setState({getAnyway: true})}>{I18n.t("submissions.get_anyway")}</a>
        )}
        {this.state.getAnyway && <p>{this.state.content}</p>}
      </div>
    );
  }
}
