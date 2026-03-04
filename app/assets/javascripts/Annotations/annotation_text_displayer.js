/** Annotation Text Displayer Class

    This class is in charge of displaying collections of Annotation Texts. It puts
    them in a div with a class called 'annotation_text_display' and is in charge of
    displaying that div at given coordinates, and hiding that div.

    Multiple texts are displayed at once, and each one is contained with a <p> tag.

    Rules:
    - Assumes existence of AnnotationText class
*/

class AnnotationTextDisplayer {
  constructor() {
    // Create the div that we will display in
    this.display_node = document.createElement("div");
    this.display_node.className = "annotation_text_display";

    const section = document.getElementById("content");
    if (!!section) {
      section.appendChild(this.display_node);
    } else {
      document.body.appendChild(this.display_node);
    }
    this.hide();
  }

  // Hide the displayer
  hide() {
    this.display_node.style.display = "none";
  }

  // Show the displayer
  show() {
    this.display_node.style.display = "block";
    window.renderMathInElement(this.display_node);
  }

  // Set the parent element of the display node
  setDisplayNodeParent(element) {
    this.display_node.remove();
    element.appendChild(this.display_node);
  }

  // Display the collection of annotations at the given location
  displayCollection(collection, x, y, units) {
    units ||= "px";
    // Are we already showing some Annotations?  Hide them then
    this.hide();

    // Return if the collection is empty
    if (collection.length === 0) {
      return;
    }

    // Now, compile all the annotations in this collection into a single
    // string to display.
    let contents = collection.map(element => element.content).join("\n\n");

    // Update the display node to be in the right position, and to have the right contents
    this.display_node.innerHTML = safe_marked(contents);
    this.display_node.style.left = x + units;
    this.display_node.style.top = y + units;

    // Show the Displayer
    this.show();
  }
}
