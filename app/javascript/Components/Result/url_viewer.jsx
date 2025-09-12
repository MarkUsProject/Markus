import React from "react";

export class URLViewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      externalURL: "",
      embeddedURL: "",
    };
  }

  componentDidMount() {
    this.fetchUrl();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.url !== this.props.url) {
      this.fetchUrl();
    } else if (prevState.externalURL !== this.state.externalURL) {
      this.configDisplay();
    }
  }

  fetchUrl = () => {
    if (!this.props.url) {
      return;
    }
    this.props.setLoadingCallback(true);
    fetch(this.props.url)
      .then(response => response.text())
      .then(content =>
        this.setState({externalURL: content}, () => this.props.setLoadingCallback(false))
      )
      .catch(error => {
        this.props.setLoadingCallback(false);
        if (error instanceof DOMException) return;
        console.error(error);
      });
  };

  configDisplay = () => {
    const url = this.isValidURL(this.state.externalURL);
    if (!url) {
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
  };

  /*
   * Takes the content from a markusurl and checks to see if it is valid HTTP(S) url.
   * Returns a url object if it is valid and false otherwise.
   */
  isValidURL = urlStr => {
    try {
      const url = new URL(urlStr);
      if ((url.protocol === "http:" || url.protocol === "https:") && url.hostname !== "") {
        return url;
      }
    } catch (e) {
      //Invalid URL
    }
    return false;
  };

  /*
   * Converts a URL object google drive/docs link into a link that allows for embedding of the associated content.
   * This link is assumed to be of the form:
   *     (docs or drive).google.com/<content_type>/.../<view_mode>
   * This then sets the embeddedURL state to that newly converted link
   */
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

  /*
   * Asynchronous function that fetches the embedded representation of a video URL using the oembed format.
   * This function then uses the returned html to get the source of the embedded content and sets the
   * embeddedURL state to that new source.
   *
   * @params url: The URL of the video to be embedded
   * @params oembedUrl: The URL endpoint to use to get the embedded representation of the video URL from
   */
  configureOEmbedPreview = (url, oembedUrl) => {
    // Request is of the form <oembedUrl>?format=json&url=<url>
    // For more information about the format of this request see https://oembed.com/
    const requestData = {format: "json", url: url};
    const queryString = new URLSearchParams(requestData).toString();
    const requestUrl = `${oembedUrl}?${queryString}`;
    fetch(requestUrl, {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
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
    } else if (!this.isValidURL(this.state.externalURL)) {
      return errorMessage(I18n.t("submissions.invalid_url", {item: `"${this.state.externalURL}"`}));
    } else {
      return errorMessage(I18n.t("submissions.url_preview_error"));
    }
  };

  render() {
    return (
      <div className="url-container">
        <div className="link-display">
          {/* Make Invalid URLs unclickable */}
          {!this.isValidURL(this.state.externalURL) ? (
            this.state.externalURL
          ) : (
            <a href={this.state.externalURL} target="_blank">
              {this.state.externalURL}
            </a>
          )}
        </div>
        <div className="display-area">{this.renderPreviewDisplay()}</div>
      </div>
    );
  }
}
