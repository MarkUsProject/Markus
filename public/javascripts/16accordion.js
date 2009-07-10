/* Simple Accordion Script 
 * Requires Prototype and Script.aculo.us Libraries
 * By: Brian Crescimanno <brian.crescimanno@gmail.com>
 * http://briancrescimanno.com
 * This work is licensed under the Creative Commons Attribution-Share Alike 3.0
 * http://creativecommons.org/licenses/by-sa/3.0/us/
 */

if (typeof Effect == 'undefined')
  throw("You must have the script.aculo.us library to use this accordion");

var Accordion = Class.create({

    initialize: function(id, defaultExpandedCount) {
        if(!$(id)) throw("Attempted to initalize accordion with id: "+ id + " which was not found.");
        this.accordion = $(id);
        this.options = {
            toggleClass: "accordion-toggle",
            toggleActive: "accordion-toggle-active",
            contentClass: "accordion-content"
        }
        this.contents = this.accordion.select('div.'+this.options.contentClass);
        this.isAnimating = false;
        this.maxHeight = 0;
        this.current = defaultExpandedCount ? this.contents[defaultExpandedCount-1] : null;
        this.toExpand = null;

        this.checkMaxHeight();
        this.initialHide();
        this.attachInitialMaxHeight();

        var clickHandler =  this.clickHandler.bindAsEventListener(this);
        this.accordion.observe('click', clickHandler);
    },

    expand: function(el) {
        this.toExpand = el.next('div.'+this.options.contentClass);
        if(this.current != this.toExpand){
	    this.toExpand.show();
            this.animate();
        }else{
	   this.toExpand = null;
	   this.animate();
	}
    },

    checkMaxHeight: function() {
        for(var i=0; i<this.contents.length; i++) {
            if(this.contents[i].getHeight() > this.maxHeight) {
                this.maxHeight = this.contents[i].getHeight();
            }
        }
    },

    attachInitialMaxHeight: function() {
       if(this.current){
		this.current.previous('div.'+this.options.toggleClass).addClassName(this.options.toggleActive);
        if(this.current.getHeight() != this.maxHeight) this.current.setStyle({height: this.maxHeight+"px"});
	}
    },

    clickHandler: function(e) {
        var el = e.element();
        if(el.hasClassName(this.options.toggleClass) && !this.isAnimating) {
            this.expand(el);
        }
    },

    initialHide: function(){
      if(this.current){
        for(var i=0; i<this.contents.length; i++){
            if(this.contents[i] != this.current) {
                this.contents[i].hide();
                this.contents[i].setStyle({height: 0});
            }
	}
      }else{
        for(var i=0; i<this.contents.length; i++){
                this.contents[i].hide();
                this.contents[i].setStyle({height: 0});
            }    
	  }
        },

    animate: function() {
        var effects = new Array();
        var options = {
            sync: true,
            scaleFrom: 0,
            scaleContent: false,
            transition: Effect.Transitions.sinoidal,
            scaleMode: {
                originalHeight: this.maxHeight,
                originalWidth: this.accordion.getWidth()
            },
            scaleX: false,
            scaleY: true
        };

	if(this.toExpand){
          effects.push(new Effect.Scale(this.toExpand, 100, options));
	}

        options = {
            sync: true,
            scaleContent: false,
            transition: Effect.Transitions.sinoidal,
            scaleX: false,
            scaleY: true
        };

        if(this.current){
          effects.push(new Effect.Scale(this.current, 0, options));
	}

        var myDuration = 0.75;

        new Effect.Parallel(effects, {
            duration: myDuration,
            fps: 35,
            queue: {
                position: 'end',
                scope: 'accordion'
            },
            beforeStart: function() {
                this.isAnimating = true;
	    if(this.current){
                this.current.previous('div.'+this.options.toggleClass).removeClassName(this.options.toggleActive);
	        }
	    if(this.toExpand){
                this.toExpand.previous('div.'+this.options.toggleClass).addClassName(this.options.toggleActive);
		}
            }.bind(this),

            afterFinish: function() {
	      if(this.current){
                this.current.hide();
		}
	       if(this.toExpand){
                this.toExpand.setStyle({ height: this.maxHeight+"px" });
                this.current = this.toExpand;
	        }else{
		this.current = null
		}

                this.isAnimating = false;
            }.bind(this)
        });
    }

});

document.observe("dom:loaded", function(){
    accordion = new Accordion("test-accordion", 0);
})
