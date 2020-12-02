import React from "react";
import {markupTextInRange} from "../Helpers/range_selector";

export class JupyterNotebookViewer extends React.Component {

  elemMarkup = (node) => {
    const elem = document.createElement('span');
    elem.style.backgroundColor = 'red';
    return elem;
  }

  getSelection = () => {
    const iframe = document.getElementById("jupyter-notebook");
    const target = (iframe.contentWindow || iframe.contentDocument);
    const range = target.getSelection().getRangeAt(0)
    markupTextInRange(range, this.elemMarkup)
  }

  render() {
    return (
      <div>
        <button onClick={this.getSelection}>{'highlight'}</button>
        <iframe className={'jupyter-notebook'} id={'jupyter-notebook'} srcDoc={this.props.content}/>
      </div>
    )
  }
}
