import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      embeddedURL: "",
      isInvalidUrl: false,
    };
  }

  componentDidMount() {
    this.configDisplay();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.externalUrl !== this.props.externalUrl) {
      this.configDisplay();
    }
  }

  configDisplay = () => {
    const url = this.parseURL(this.props.externalUrl);
    if (!url) {
      this.setState({isInvalidUrl: true});
      return;
    }
    switch (url.hostname) {
      case "docs.google.com":
      case "drive.google.com":
        this.configureGoogleDrivePreview(url);
        break;
      case "www.youtube.com":
      case "youtu.be":
        this.configureOEmbedPreview(url.toString(), "https://www.youtube.com/oembed");
        break;
      default:
        this.setState({embeddedURL: ""});
    }
    this.setState({isInvalidUrl: false});
  };

  /*
   * Takes the content from a markusurl and checks to see if it is valid HTTP(S) url.
   * Returns a url object if it is valid and nothing otherwise.
   */
  parseURL = urlStr => {
    try {
      const url = new URL(urlStr);
      if ((url.protocol === "http:" || url.protocol === "https:") && url.hostname !== "") {
        return url;
      }
    } catch (e) {
      //Invalid URL
    }
  };

  configureGoogleDrivePreview = url => {
    const path = url.pathname.split("/");
    if (path[1] === "forms") {
      path[path.length - 1] = "/viewform";
    } else {
      path[path.length - 1] = "/preview";
    }
    url.pathname = path.join("/");
    this.setState({
      embeddedURL: url.toString(),
    });
  };

  configureOEmbedPreview = (url, oembedUrl) => {
    $.get(oembedUrl, {format: "json", url: url}).then(res => {
      const match = res.html.match(/src="(\S+)"/);
      if (match.length === 2) {
        this.setState({
          embeddedURL: match[1],
        });
      }
    });
  };

  renderPreviewDisplay = () => {
    const errorMessage = message => {
      return <div className="url-message-display">{message}</div>;
    };
    if (this.state.embeddedURL !== "") {
      return (
        <iframe className="url-display" src={this.state.embeddedURL} allowFullScreen>
          {errorMessage(I18n.t("submissions.url_preview_error"))}
        </iframe>
      );
    } else if (this.state.isInvalidUrl) {
      return errorMessage(I18n.t("submissions.invalid_url", {item: I18n.t("this")}));
    } else {
      return errorMessage(I18n.t("submissions.url_preview_error"));
    }
  };

  render() {
    return (
      <div className="url-container">
        <div className="link-display">
          {/* Make Invalid URLs unclickable */}
          {this.state.isInvalidUrl ? (
            this.props.externalUrl
          ) : (
            <a href={this.props.externalUrl} target="_blank">
              {this.props.externalUrl}
            </a>
          )}
        </div>
        <div className="display-area">{this.renderPreviewDisplay()}</div>
      </div>
    );
  }
}
