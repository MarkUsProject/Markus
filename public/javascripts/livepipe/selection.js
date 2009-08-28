/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/control/selection
 * @require prototype.js, effects.js, draggable.js, livepipe.js
 */

if(typeof(Prototype) == "undefined")
	throw "Control.Selection requires Prototype to be loaded.";
if(typeof(Object.Event) == "undefined")
	throw "Control.Selection requires Object.Event to be loaded.";

Control.Selection = {
	options: {
		resize_layout_timeout: 125,
		selected: Prototype.emptyFunction,
		deselected: Prototype.emptyFunction,
		change: Prototype.emptyFunction,
		selection_id: 'control_selection',
		selection_style: {
			zIndex: 999,
			cursor: 'default',
			border: '1px dotted #000'
		},
		filter: function(element){
			return true;
		},
		drag_proxy: false,
		drag_proxy_threshold: 1,
		drag_proxy_options: {}
	},
	selectableElements: [],
	elements: [],
	selectableObjects: [],
	objects: [],
	active: false,
	container: false,
	resizeTimeout: false,
	load: function(options){
		Control.Selection.options = Object.extend(Control.Selection.options,options || {});
		Control.Selection.selection_div = $(document.createElement('div'));
		Control.Selection.selection_div.id = Control.Selection.options.selection_id;
		Control.Selection.selection_div.style.display = 'none';
		Control.Selection.selection_div.setStyle(Control.Selection.options.selection_style);
		Control.Selection.border_width = parseInt(Control.Selection.selection_div.getStyle('border-top-width')) * 2;
		Control.Selection.container = Prototype.Browser.IE ? window.container : window;
		$(document.body).insert(Control.Selection.selection_div);
		Control.Selection.enable();
		if(Control.Selection.options.drag_proxy && typeof(Draggable) != 'undefined')
			Control.Selection.DragProxy.load();
		Event.observe(window,'resize',function(){
			if(Control.Selection.resizeTimeout)
				window.clearTimeout(Control.Selection.resizeTimeout);
			Control.Selection.resizeTimeout = window.setTimeout(Control.Selection.recalculateLayout,Control.Selection.options.resize_layout_timeout);
		});
		if(Prototype.Browser.IE){
			var body = $$('body').first();
			body.observe('mouseleave',Control.Selection.stop);
			body.observe('mouseup',Control.Selection.stop);
		}
	},
	enable: function(){
		if(Prototype.Browser.IE){
			document.onselectstart = function(){
				return false;
			}
		}
		Event.observe(Control.Selection.container,'mousedown',Control.Selection.start);
		Event.observe(Control.Selection.container,'mouseup',Control.Selection.stop);
	},
	disable: function(){
		if(Prototype.Browser.IE){
			document.onselectstart = function(){
				return true;
			}
		}
		Event.stopObserving(Control.Selection.container,'mousedown',Control.Selection.start);
		Event.stopObserving(Control.Selection.container,'mouseup',Control.Selection.stop);
	},
	recalculateLayout: function(){
		Control.Selection.selectableElements.each(function(element){
			var dimensions = element.getDimensions();
			var offset = element.cumulativeOffset();
			var scroll_offset = element.cumulativeScrollOffset();
			if(!element._control_selection)
				element._control_selection = {};
			element._control_selection.top = offset[1] - scroll_offset[1];
			element._control_selection.left = offset[0] - scroll_offset[0];
			element._control_selection.width = dimensions.width;
			element._control_selection.height = dimensions.height;
		});
	},
	addSelectable: function(element,object,activation_targets,activation_target_callback){
		element = $(element);
		if(activation_targets)
			activation_targets = activation_targets.each ? activation_targets : [activation_targets];
		var dimensions = element.getDimensions();
		var offset = Position.cumulativeOffset(element);
		element._control_selection = {
			activation_targets: activation_targets,
			is_selected: false,
			top: offset[1],
			left: offset[0],
			width: dimensions.width,
			height: dimensions.height,
			activationTargetMouseMove: function(){
				Control.Selection.notify('activationTargetMouseMove',element);
				if(activation_targets){
					activation_targets.each(function(activation_target){
						activation_target.stopObserving('mousemove',element._control_selection.activationTargetMouseMove);
					});
				}
				Control.Selection.DragProxy.container.stopObserving('mousemove',element._control_selection.activationTargetMouseMove);
			},
			activationTargetMouseDown: function(event){
				if(!Control.Selection.elements.include(element))
					Control.Selection.select(element);
				Control.Selection.DragProxy.start(event);
				Control.Selection.DragProxy.container.hide();
				if(activation_targets){
					activation_targets.each(function(activation_target){
						activation_target.observe('mousemove',element._control_selection.activationTargetMouseMove);
					});
				}
				Control.Selection.DragProxy.container.observe('mousemove',element._control_selection.activationTargetMouseMove);
			},
			activationTargetClick: function(){
				Control.Selection.select(element);
				if(typeof(activation_target_callback) == "function")
					activation_target_callback();
				if(activation_targets){
					activation_targets.each(function(activation_target){
						activation_target.stopObserving('mousemove',element._control_selection.activationTargetMouseMove);
					});
				}
				Control.Selection.DragProxy.container.stopObserving('mousemove',element._control_selection.activationTargetMouseMove);
			}
		};
		element.onselectstart = function(){
			return false;
		};
		element.unselectable = 'on';
		element.style.MozUserSelect = 'none';
		if(activation_targets){
			activation_targets.each(function(activation_target){
				activation_target.observe('mousedown',element._control_selection.activationTargetMouseDown);
				activation_target.observe('click',element._control_selection.activationTargetClick);
			});
		}
		Control.Selection.selectableElements.push(element);
		Control.Selection.selectableObjects.push(object);
	},
	removeSelectable: function(element){
		element = $(element);
		if(element._control_selection.activation_targets){
			element._control_selection.activation_targets.each(function(activation_target){
				activation_target.stopObserving('mousedown',element._control_selection.activationTargetMouseDown);
			});
			element._control_selection.activation_targets.each(function(activation_target){
				activation_target.stopObserving('click',element._control_selection.activationTargetClick);
			});
		}
		element._control_selection = null;
		element.onselectstart = function() {
			return true;
		};
		element.unselectable = 'off';
		element.style.MozUserSelect = '';
		var position = 0;
		Control.Selection.selectableElements.each(function(selectable_element,i){
			if(selectable_element == element){
				position = i;
				throw $break;
			}
		});
		Control.Selection.selectableElements = Control.Selection.selectableElements.without(element);
		Control.Selection.selectableObjects = Control.Selection.selectableObjects.slice(0,position).concat(Control.Selection.selectableObjects.slice(position + 1))
	},
	select: function(selected_elements){
		if(typeof(selected_elements) == "undefined" || !selected_elements)
			selected_elements = [];
		if(!selected_elements.each && !selected_elements._each)
			selected_elements = [selected_elements];
		//comparing the arrays directly wouldn't equate to true in safari so we need to compare each item
		var selected_items_have_changed = !(Control.Selection.elements.length == selected_elements.length && Control.Selection.elements.all(function(item,i){
			return selected_elements[i] == item;
		}));
		if(!selected_items_have_changed)
			return;
		var selected_objects_indexed_by_element = {};
		var selected_objects = selected_elements.collect(function(selected_element){
			var selected_object = Control.Selection.selectableObjects[Control.Selection.selectableElements.indexOf(selected_element)];
			selected_objects_indexed_by_element[selected_element] = selected_object;
			return selected_object;
		});
		if(Control.Selection.elements.length == 0 && selected_elements.length != 0){
			selected_elements.each(function(element){
				Control.Selection.notify('selected',element,selected_objects_indexed_by_element[element]);
			});
		}else{
			Control.Selection.elements.each(function(element){
				if(!selected_elements.include(element)){
					Control.Selection.notify('deselected',element,selected_objects_indexed_by_element[element]);
				}
			});
			selected_elements.each(function(element){
				if(!Control.Selection.elements.include(element)){
					Control.Selection.notify('selected',element,selected_objects_indexed_by_element[element]);
				}
			});
		}
		Control.Selection.elements = selected_elements;
		Control.Selection.objects = selected_objects;
		Control.Selection.notify('change',Control.Selection.elements,Control.Selection.objects);
	},
	deselect: function(){
		if(Control.Selection.notify('deselect') === false)
			return false;
		Control.Selection.elements.each(function(element){
			Control.Selection.notify('deselected',element,Control.Selection.selectableObjects[Control.Selection.selectableElements.indexOf(element)]);
		});
		Control.Selection.objects = [];
		Control.Selection.elements = [];
		Control.Selection.notify('change',Control.Selection.objects,Control.Selection.elements);
		return true;
	},
	//private
	start: function(event){
		if(!event.isLeftClick() || Control.Selection.notify('start',event) === false)
			return false;
		if(!event.shiftKey && !event.altKey)
			Control.Selection.deselect();
		Event.observe(Control.Selection.container,'mousemove',Control.Selection.onMouseMove);
		Event.stop(event);
		return false;
	},
	stop: function(){
		Event.stopObserving(Control.Selection.container,'mousemove',Control.Selection.onMouseMove);
		Control.Selection.active = false;
		Control.Selection.selection_div.setStyle({
			display: 'none',
			top: null,
			left: null,
			width: null,
			height: null
		});
		Control.Selection.start_mouse_coordinates = {};
		Control.Selection.current_mouse_coordinates = {};
	},
	mouseCoordinatesFromEvent: function(event){
		return {
			x: Event.pointerX(event),
			y: Event.pointerY(event)
		};
	},
	onClick: function(event,element,source){
		var selection = [];
		if(event.shiftKey){
			selection = Control.Selection.elements.clone();
			if(!selection.include(element))
				selection.push(element);
		}else if(event.altKey){
			selection = Control.Selection.elements.clone();
			if(selection.include(element))
				selection = selection.without(element);
		}else{
			selection = [element];
		}
		Control.Selection.select(selection);
		if(source == 'click')
			Event.stop(event);
	},
	onMouseMove: function(event){
		if(!Control.Selection.active){
			Control.Selection.active = true;
			Control.Selection.start_mouse_coordinates = Control.Selection.mouseCoordinatesFromEvent(event);
		}else{
			Control.Selection.current_mouse_coordinates = Control.Selection.mouseCoordinatesFromEvent(event);
			Control.Selection.drawSelectionDiv();
			var current_selection = Control.Selection.selectableElements.findAll(function(element){
				return Control.Selection.options.filter(element) && Control.Selection.elementWithinSelection(element);
			});
			if(event.shiftKey && !event.altKey){
				Control.Selection.elements.each(function(element){
					if(!current_selection.include(element))
						current_selection.push(element);
				});
			}else if(event.altKey && !event.shiftKey){
				current_selection = Control.Selection.elements.findAll(function(element){
					return !current_selection.include(element);
				});
			}
			Control.Selection.select(current_selection);
		}
	},
	drawSelectionDiv: function(){
		if(Control.Selection.start_mouse_coordinates == Control.Selection.current_mouse_coordinates){
			Control.Selection.selection_div.style.display = 'none';
		}else{
			Control.Selection.viewport = document.viewport.getDimensions();
			Control.Selection.selection_div.style.position = 'absolute';
			Control.Selection.current_direction = (Control.Selection.start_mouse_coordinates.y > Control.Selection.current_mouse_coordinates.y ? 'N' : 'S') + (Control.Selection.start_mouse_coordinates.x < Control.Selection.current_mouse_coordinates.x ? 'E' : 'W');
			Control.Selection.selection_div.setStyle(Control.Selection['dimensionsFor' + Control.Selection.current_direction]());
			Control.Selection.selection_div.style.display = 'block';
		}
	},
	dimensionsForNW: function(){
		return {
			top: (Control.Selection.start_mouse_coordinates.y - (Control.Selection.start_mouse_coordinates.y - Control.Selection.current_mouse_coordinates.y)) + 'px',
			left: (Control.Selection.start_mouse_coordinates.x - (Control.Selection.start_mouse_coordinates.x - Control.Selection.current_mouse_coordinates.x)) + 'px',
			width: (Control.Selection.start_mouse_coordinates.x - Control.Selection.current_mouse_coordinates.x) + 'px',
			height: (Control.Selection.start_mouse_coordinates.y - Control.Selection.current_mouse_coordinates.y) + 'px'
		};
	},
	dimensionsForNE: function(){
		return {
			top: (Control.Selection.start_mouse_coordinates.y - (Control.Selection.start_mouse_coordinates.y - Control.Selection.current_mouse_coordinates.y)) + 'px',
			left: Control.Selection.start_mouse_coordinates.x + 'px',
			width: Math.min((Control.Selection.viewport.width - Control.Selection.start_mouse_coordinates.x) - Control.Selection.border_width,Control.Selection.current_mouse_coordinates.x - Control.Selection.start_mouse_coordinates.x) + 'px',
			height: (Control.Selection.start_mouse_coordinates.y - Control.Selection.current_mouse_coordinates.y) + 'px'
		};
	},
	dimensionsForSE: function(){
		return {
			top: Control.Selection.start_mouse_coordinates.y + 'px',
			left: Control.Selection.start_mouse_coordinates.x + 'px',
			width: Math.min((Control.Selection.viewport.width - Control.Selection.start_mouse_coordinates.x) - Control.Selection.border_width,Control.Selection.current_mouse_coordinates.x - Control.Selection.start_mouse_coordinates.x) + 'px',
			height: Math.min((Control.Selection.viewport.height - Control.Selection.start_mouse_coordinates.y) - Control.Selection.border_width,Control.Selection.current_mouse_coordinates.y - Control.Selection.start_mouse_coordinates.y) + 'px'
		};
	},
	dimensionsForSW: function(){
		return {
			top: Control.Selection.start_mouse_coordinates.y + 'px',
			left: (Control.Selection.start_mouse_coordinates.x - (Control.Selection.start_mouse_coordinates.x - Control.Selection.current_mouse_coordinates.x)) + 'px',
			width: (Control.Selection.start_mouse_coordinates.x - Control.Selection.current_mouse_coordinates.x) + 'px',
			height: Math.min((Control.Selection.viewport.height - Control.Selection.start_mouse_coordinates.y) - Control.Selection.border_width,Control.Selection.current_mouse_coordinates.y - Control.Selection.start_mouse_coordinates.y) + 'px'
		};
	},
	inBoundsForNW: function(element,selection){
		return (
			((element.left > selection.left || element.right > selection.left) && selection.right > element.left) &&
			((element.top > selection.top || element.bottom > selection.top) && selection.bottom > element.top)
		);
	},
	inBoundsForNE: function(element,selection){
		return (
			((element.left < selection.right || element.left < selection.right) && selection.left < element.right) &&
			((element.top > selection.top || element.bottom > selection.top) && selection.bottom > element.top)
		);
	},
	inBoundsForSE: function(element,selection){
		return (
			((element.left < selection.right || element.left < selection.right) && selection.left < element.right) &&
			((element.bottom < selection.bottom || element.top < selection.bottom) && selection.top < element.bottom)
		);
	},
	inBoundsForSW: function(element,selection){
		return (
			((element.left > selection.left || element.right > selection.left) && selection.right > element.left) &&
			((element.bottom < selection.bottom || element.top < selection.bottom) && selection.top < element.bottom)
		);
	},
	elementWithinSelection: function(element){
		if(Control.Selection['inBoundsFor' + Control.Selection.current_direction]({
			top: element._control_selection.top,
			left: element._control_selection.left,
			bottom: element._control_selection.top + element._control_selection.height,
			right: element._control_selection.left + element._control_selection.width
		},{
			top: parseInt(Control.Selection.selection_div.style.top),
			left: parseInt(Control.Selection.selection_div.style.left),
			bottom: parseInt(Control.Selection.selection_div.style.top) + parseInt(Control.Selection.selection_div.style.height),
			right: parseInt(Control.Selection.selection_div.style.left) + parseInt(Control.Selection.selection_div.style.width)
		})){
			element._control_selection.is_selected = true;
			return true;
		}else{
			element._control_selection.is_selected = false;
			return false;
		}
	},
	DragProxy: {
	    active: false,
		xorigin: 0,
		yorigin: 0,
		load: function(){
			Control.Selection.DragProxy.container = $(document.createElement('div'));
			Control.Selection.DragProxy.container.id = 'control_selection_drag_proxy';
			Control.Selection.DragProxy.container.setStyle({
				position: 'absolute',
				top: '1px',
				left: '1px',
				zIndex: 99999
			});
			Control.Selection.DragProxy.container.hide();
			document.body.appendChild(Control.Selection.DragProxy.container);
			Control.Selection.observe('selected',Control.Selection.DragProxy.selected);
			Control.Selection.observe('deselected',Control.Selection.DragProxy.deselected);
		},
		start: function(event){            
			if(event.isRightClick()){
				Control.Selection.DragProxy.container.hide();
				return;
			}		    
			if(Control.Selection.DragProxy.xorigin == Event.pointerX(event) && Control.Selection.DragProxy.yorigin == Event.pointerY(event))
				return;    		
		    Control.Selection.DragProxy.active = true;
			Control.Selection.DragProxy.container.setStyle({
				position: 'absolute',
				top: Event.pointerY(event) + 'px',
				left: Event.pointerX(event) + 'px'
			});			
			Control.Selection.DragProxy.container.observe('mouseup',Control.Selection.DragProxy.onMouseUp);			
			Control.Selection.DragProxy.container.show();
			Control.Selection.DragProxy.container._draggable = new Draggable(Control.Selection.DragProxy.container,Object.extend({
				onEnd: Control.Selection.DragProxy.stop
			},Control.Selection.options.drag_proxy_options));
			Control.Selection.DragProxy.container._draggable.eventMouseDown(event);			
			Control.Selection.DragProxy.notify('start',Control.Selection.DragProxy.container,Control.Selection.elements);
		},
		stop: function(){
			window.setTimeout(function(){
				Control.Selection.DragProxy.active = false;
				Control.Selection.DragProxy.container.hide();
    			if(Control.Selection.DragProxy.container._draggable){
					Control.Selection.DragProxy.container._draggable.destroy();
					Control.Selection.DragProxy.container._draggable = null;
    			}
    			Control.Selection.DragProxy.notify('stop');
		    },1);
		},
		onClick: function(event){
			Control.Selection.DragProxy.xorigin = Event.pointerX(event);
			Control.Selection.DragProxy.yorigin = Event.pointerY(event);
			if(event.isRightClick())
				Control.Selection.DragProxy.container.hide();
			if(Control.Selection.elements.length >= Control.Selection.options.drag_proxy_threshold && !(event.shiftKey || event.altKey) && (Control.Selection.DragProxy.xorigin != Event.pointerX(event) || Control.Selection.DragProxy.yorigin != Event.pointerY(event))){
				Control.Selection.DragProxy.start(event);
				Event.stop(event);
			}
		},
		onMouseUp: function(event){
			Control.Selection.DragProxy.stop();
			Control.Selection.DragProxy.container.stopObserving('mouseup',Control.Selection.DragProxy.onMouseUp);
		},
		selected: function(element){
			element.observe('mousedown',Control.Selection.DragProxy.onClick);
		},
		deselected: function(element){
			element.stopObserving('mousedown',Control.Selection.DragProxy.onClick);
		}
	}
};
Object.Event.extend(Control.Selection);
Object.Event.extend(Control.Selection.DragProxy);