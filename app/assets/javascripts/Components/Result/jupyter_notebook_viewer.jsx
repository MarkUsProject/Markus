import React from "react";

export class JupyterNotebookViewer extends React.Component {
  // TODO: create annotation layer and link annotations to html elements in the iframe
  render() {
    return (
      <div>
        <iframe className={'jupyter-notebook'} id={'jupyter-notebook'} srcDoc={this.props.content}/>
      </div>
    )
  }
}
