// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//

/** Helper functions for managing DOM elements' classes via pure JavaScript. */

Element.prototype.addClass = function (className) {
  if (this.classList) {
    this.classList.add(className);
  } else {
    this.className += " " + className;
  }
};

Element.prototype.removeClass = function (className) {
  if (this.classList) {
    this.classList.remove(className);
  } else {
    this.className = this.className.replace(
      new RegExp("(^|\\b)" + className.split(" ").join("|") + "(\\b|$)", "gi"),
      " "
    );
  }
};

Element.prototype.hasClass = function (className) {
  if (this.classList) {
    return this.classList.contains(className);
  } else {
    return new RegExp("(^| )" + className + "( |$)", "gi").test(this.className);
  }
};
