import React from "react";

export class BinaryViewer extends React.PureComponent {
  state = {content: null};

  componentDidMount() {
    // Notify the parent component that the file content is loading.
    this.props.setLoadingCallback(true);

    this.fetchContent(this.props.url).then(content => {
      this.setState({content: content}, () => this.props.setLoadingCallback(false));
    });
  }

  componentDidUpdate(prevProps, prevState) {
    this.props.setLoadingCallback(true);

    if (this.props.url && this.props.url !== prevProps.url) {
      // The URL has updated, so the content needs to be fetched using the new URL.
      this.fetchContent(this.props.url).then(content =>
        this.setState({content: content}, this.props.setLoadingCallback(false))
      );
    }
  }

  fetchContent(url) {
    return fetch(url)
      .then(response => response.text())
      .then(content => content.replace(/\r?\n/gm, "\n"))
      .catch(error => {
        console.error(error);
        this.props.setErrorMessageCallback("Failed to load the file.");
      });
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
