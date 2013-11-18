/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/control/contextmenu
 * @require prototype.js, livepipe.js
 */

if(typeof(Prototype) == "undefined")
	throw "Control.ContextMenu requires Prototype to be loaded.";
if(typeof(Object.Event) == "undefined")
	throw "Control.ContextMenu requires Object.Event to be loaded.";

Control.ContextMenu = Class.create({
	initialize: function(container,options){
		Control.ContextMenu.load();
		this.options = Object.extend({
			leftClick: false,
			disableOnShiftKey: true,
			disableOnAltKey: true,
			selectedClassName: 'selected',
			activatedClassName: 'activated',
			animation: true,
			animationCycles: 2,
			animationLength: 300,
			delayCallback: true
		},options || {});
		this.activated = false;
		this.items = this.options.items || [];
		this.container = $(container);
		this.container.observe(this.options.leftClick ? 'click' : (Prototype.Browser.Opera ? 'click' : 'contextmenu'),function(event){
			if(!Control.ContextMenu.enabled || Prototype.Browser.Opera && !event.ctrlKey)
				return;
			this.open(event);
		}.bindAsEventListener(this));
	},
	open: function(event){
		if(Control.ContextMenu.current && !Control.ContextMenu.current.close())
			return;
		if(this.notify('beforeOpen',event) === false)
			return false;
		this.buildMenu();
		if(this.items.length == 0){
			this.close(event);
			return false;
		}
		Control.ContextMenu.current = this;
		Control.ContextMenu.positionContainer(event);
		Control.ContextMenu.container.show();
		if(this.notify('afterOpen',event) === false)
			return false;
		event.stop();
		return true;
	},
	close: function(event){
		if(event)
			event.stop();
		if(this.notify('beforeClose') === false)
			return false;
		Control.ContextMenu.current = false;
		this.activated = false;
		Control.ContextMenu.container.removeClassName(this.options.activatedClassName);
		Control.ContextMenu.container.select('li').invoke('stopObserving');
		Control.ContextMenu.container.hide();
		Control.ContextMenu.container.update('');
		if(this.notify('afterClose') === false)
			return false;
		return true;
	},
	buildMenu: function(){
		var list = document.createElement('ul');
		Control.ContextMenu.container.appendChild(list);
		this.items.each(function(item){
			if(!(!item.condition || item.condition && item.condition() !== false))
				return;
			var item_container = $(document.createElement('li'));
			item_container.update($value(item.label));
			list.appendChild(item_container);
			item_container[$value(item.enabled) ? 'removeClassName' : 'addClassName']('disabled');
			item_container.observe('mousedown',function(event,item){
				if(!$value(item.enabled))
					return event.stop();
				this.activated = $value(item.label);
			}.bindAsEventListener(this,item));
			item_container.observe('click',this.selectMenuItem.bindAsEventListener(this,item,item_container));
			item_container.observe('contextmenu',this.selectMenuItem.bindAsEventListener(this,item,item_container));
		}.bind(this));
	},
	addItem: function(params){
		if(!'enabled' in params)
			params.enabled = true;
		this.items.push(params);
		return this;
	},
	destroy: function(){
		this.container.stopObserving(Prototype.Browser.Opera || this.options.leftClick ? 'click' : 'contextmenu');
		this.items = [];
	},
	selectMenuItem: function(event,item,item_container){
		if(!$value(item.enabled))
			return event.stop();
		if(!this.activated || this.activated == $value(item.label)){
			if(this.options.animation){
				Control.ContextMenu.container.addClassName(this.options.activatedClassName);
				$A($R(0,this.options.animationCycles * 2)).each(function(i){
					window.setTimeout(function(){
						item_container.toggleClassName(this.options.selectedClassName);
					}.bind(this),i * parseInt(this.options.animationLength / (this.options.animationCycles * 2)));
				}.bind(this));
				window.setTimeout(function(){
					if(this.close() && this.options.delayCallback)
						item.callback();
				}.bind(this),this.options.animationLength);
				if(!this.options.delayCallback)
					item.callback();
			}else if(this.close())
				item.callback();
		}
		event.stop();
		return false;
	}
});
Object.extend(Control.ContextMenu,{
	loaded: false,
	capture_all: false,
	menus: [],
	current: false,
	enabled: false,
	offset: 4,
	load: function(capture_all){
		if(Control.ContextMenu.loaded)
			return;
		Control.ContextMenu.loaded = true;
		if(typeof(capture_all) == 'undefined')
			capture_all = false;
		Control.ContextMenu.capture_all = capture_all;
		Control.ContextMenu.container = $(document.createElement('div'));
		Control.ContextMenu.container.id = 'control_contextmenu';
		Control.ContextMenu.container.style.position = 'absolute';
		Control.ContextMenu.container.style.zIndex = 99999;
		Control.ContextMenu.container.hide();
		document.body.appendChild(Control.ContextMenu.container);
		Control.ContextMenu.enable();
	},
	enable: function(){
		Control.ContextMenu.enabled = true;
		Event.observe(document.body,'click',Control.ContextMenu.onClick);
		if(Control.ContextMenu.capture_all)
			Event.observe(document.body,'contextmenu',Control.ContextMenu.onContextMenu);
	},
	disable: function(){
		Event.stopObserving(document.body,'click',Control.ContextMenu.onClick);
		if(Control.ContextMenu.capture_all)
			Event.stopObserving(document.body,'contextmenu',Control.ContextMenu.onContextMenu);					
	},
	onContextMenu: function(event){
		event.stop();
		return false;
	},
	onClick: function(){
		if(Control.ContextMenu.current)
			Control.ContextMenu.current.close();
	},
	positionContainer: function(event){
		var dimensions = Control.ContextMenu.container.getDimensions();
		var top = Event.pointerY(event);
		var left = Event.pointerX(event);
		var bottom = dimensions.height + top;
		var right = dimensions.width + left;
		var viewport_dimensions = document.viewport.getDimensions();
		var viewport_scroll_offsets = document.viewport.getScrollOffsets();
		if(bottom > viewport_dimensions.height + viewport_scroll_offsets.top)
			top -= bottom - ((viewport_dimensions.height  + viewport_scroll_offsets.top) - Control.ContextMenu.offset);
		if(right > viewport_dimensions.width + viewport_scroll_offsets.left)
			left -= right - ((viewport_dimensions.width + viewport_scroll_offsets.left) - Control.ContextMenu.offset);
		Control.ContextMenu.container.setStyle({
			top: top + 'px',
			left: left + 'px'
		});
	}
});
Object.Event.extend(Control.ContextMenu);