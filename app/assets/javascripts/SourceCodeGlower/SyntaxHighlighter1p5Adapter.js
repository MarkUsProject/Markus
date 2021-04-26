/** Syntax Highlighter 1.5 Adapter Class

    This class implements the SourceCodeAdapter abstract class.

    This takes the DOM elements that the Syntax Highlighter library creates,
    and generates the DOM nodes that we're looking for.

    This class also does any modifications / hackery necessary to the Syntax Highlighter.
    In this case, it implements the font increase and decrease functions

    Rules:
    - Assumes existence of SourceCodeAdapter abstract class
*/


// Syntax Highlighter generates an Ordered List DOM tree. For this adapter,
// we pass it the root of that tree...
function SyntaxHighlighter1p5Adapter(root_of_ol) {
  this.root = root_of_ol;
  this.font_size = 1;
}

SyntaxHighlighter1p5Adapter.prototype = Object.create(SourceCodeAdapter.prototype);

SyntaxHighlighter1p5Adapter.prototype.constructor = SyntaxHighlighter1p5Adapter;

// Returns an Enumerable collection of DOM nodes representing the source code lines,
// in order.
SyntaxHighlighter1p5Adapter.prototype.getSourceNodes = function() {
  return this.root.children;
}

// Given some node, traverses upwards until it finds the LI element that represents a line of code in SyntaxHighlighter.
// This is useful for figuring out what text is currently selected, using window.getSelection().anchorNode / focusNode
SyntaxHighlighter1p5Adapter.prototype.getRootFromSelection = function(some_node) {
  if (some_node == null) {
    return null;
  }

  var current_node = some_node;
  while (current_node != null && current_node.tagName != 'LI') {
    current_node = current_node.parentNode;
  }
  return current_node;
}

SyntaxHighlighter1p5Adapter.prototype.getFontSize = function() {
  return this.font_size;
}

SyntaxHighlighter1p5Adapter.prototype.setFontSize = function(font_size) {
  this.font_size = font_size;
}

SyntaxHighlighter1p5Adapter.prototype.applyMods = function() {
  // We're going to extend Syntax Highlighters menu, and give it some new
  // commands
  if (dp == null) {
    throw("Could not modify Syntax Highlighter: DP doesn't exist");
  }

  var me = this;
  var original_commands = dp.sh.Toolbar.Commands;

  // Get rid of some commands and add font size commands
  delete original_commands.ViewSource;
  delete original_commands['PrintSource'];
  delete original_commands['ExpandSource'];

  original_commands.CopyToClipboard = {
    label: I18n.t('results.copy_text'),
    func: function() {
      navigator.clipboard.writeText(code.textContent).then(() => {
          let copy_code = document.getElementById(original_commands.CopyToClipboard.label);
          original_commands.CopyToClipboard.label = '✔ ' + I18n.t('results.copy_text');
          //update id attribute with new label
          let id = document.createAttribute('id');
          id.value = original_commands.CopyToClipboard.label;
          copy_code.setAttributeNode(id);
          copy_code.innerText = original_commands.CopyToClipboard.label;
        });
    }
  };

  original_commands["BoostCode"] = {
    label: '+A',
    func: function(highlighter) {
      var code = document.getElementsByClassName('dp-highlighter')[0];
      var font_size = me.getFontSize() + .25;
      me.setFontSize(font_size);
      code.style.fontSize = font_size + 'em';
    }
  };

  original_commands["ShrinkCode"] = {
    label: '-A',
    func: function(highlighter) {
      var code = document.getElementsByClassName('dp-highlighter')[0];
      var font_size = me.getFontSize() - .25;
      me.setFontSize(font_size);
      code.style.fontSize = font_size + 'em';
    }
  };

  // A hack to put the About at the end
  var about = original_commands['About'];
  delete original_commands['About'];
  original_commands['About'] = about;

  // Attempt to replace tools menu with these new commands
  if (!!document.getElementsByClassName('tools')[0]) {
    let tools = document.getElementsByClassName('tools')[0];
    tools.innerHTML = '';
    Object.entries(original_commands).forEach(entry => {
      let [name, {label}] = entry;
      let tool = document.createElement('a');
      let href = document.createAttribute('href');
      let id = document.createAttribute('id');
      href.value = '#';
      id.value = label;
      tool.setAttributeNode(href);
      tool.setAttributeNode(id);
      tool.addEventListener('click', (e) => {
        dp.sh.Toolbar.Command(name, e.target);
        e.preventDefault();
      });
      tool.innerText = label;
      tools.appendChild(tool);
    });
  }
}
