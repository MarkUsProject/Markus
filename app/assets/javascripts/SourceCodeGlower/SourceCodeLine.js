/** Source Code Line Class

    This class represents a single line of source code, and controls "glowing", and
    mouseover/mouseout observing.  It's an abstract class that needs to be implemented
    for the particular source code highlighting library being used

    Rules:
    - When a line is "glowing", it has a class of "source_code_glowing_" and then
      a number indicating the "depth" of its glow.  This allows for annotation overlapping.
      For example, 5 lines of source could be "glowed", and then three lines within that
      original 5 could be glowed again - their glow depth will increase.
    - This is an abstract class that needs to be implemented for the particular source
      code highlighting library being used
*/

var SourceCodeLine = Class.create({
  initialize: function(line_node) {
    // line_node is the DOM element that holds a line of source code
    this.line_node         = line_node;
    this.glow_depth        = 0;
    this.observe_over_func = null;
    this.observe_out_func  = null;
    this.is_observing      = false;
  },

  // Increase a Source Code Line's glow depth
  glow: function() {
    // Increase the depth
    this.incGlowDepth(1);

    // Add the appropriate glow class
    this.getLineNode().classList.add('source_code_glowing_' + this.getGlowDepth());
  },

  // Decrease a Source Code Line's glow depth
  unGlow: function() {
    // Decrease the glow depth
    this.decGlowDepth(1);

    // Is this line glowing?
    if (this.isGlowing()) {
      this.getLineNode().classList.remove('source_code_glowing_' + this.getGlowDepth());
    }
  },

  incGlowDepth: function(amount) {
    this.setGlowDepth(this.getGlowDepth() + amount);
  },

  decGlowDepth: function(amount) {
    this.setGlowDepth(max(this.getGlowDepth() - amount, 0);
  },

  getLineNode: function() {
    return this.line_node;
  },

  getGlowDepth: function() {
    return this.glow_depth;
  },

  setGlowDepth: function(glow_depth) {
    this.glow_depth = glow_depth;
  },

  isGlowing: function() {
    return this.getGlowDepth() > 0;
  },

  // Some hook functions for before/after glowing
  beforeUnGlow: function() {
    //hook
  },
  afterUnGlow: function() {
    //hook
  },

  // Handle all observations, and store references in the functions so that
  // we can remove observations easily
  observe: function(over_func, out_func) {
    // If we're already observing, we don't need to do this.
    if (this.isObserving()) { return; }

    this.setObserveOverFunc(over_func);
    this.setObserveOutFunc(out_func);
    this.getLineNode().onmouseover = this.getObserveOverFunc();
    this.getLineNode().onmouseout  = this.getObserveOutFunc();
    this.setObserving(true);
  },

  stopObserving: function() {
    // If we're not observing this, this isn't a problem
    if (!this.isObserving()) { return; }

    this.getLineNode().onmouseover = null;
    this.getLineNode().onmouseout  = null;
    this.setObserving(false);
  },

  setObserveOverFunc: function(func) {
    this.observe_over_func = func;
  },

  getObserveOverFunc: function() {
    return this.observe_over_func;
  },

  setObserveOutFunc: function(func) {
    this.observe_out_func = func;
  },

  getObserveOutFunc: function(func) {
    return this.observe_out_func;
  },

  isObserving: function() {
    return this.is_observing;
  },

  setObserving: function(is_observing) {
    this.is_observing = is_observing;
  }
});
