/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/control/rating
 * @require prototype.js, livepipe.js
 */

if(typeof(Prototype) == "undefined")
	throw "Control.Rating requires Prototype to be loaded.";
if(typeof(Object.Event) == "undefined")
	throw "Control.Rating requires Object.Event to be loaded.";

Control.Rating = Class.create({
	initialize: function(container,options){
		Control.Rating.instances.push(this);
		this.value = false;
		this.links = [];
		this.container = $(container);
		this.container.update('');
		this.options = {
			min: 1,
			max: 5,
			rated: false,
			input: false,
			reverse: false,
			capture: true,
			multiple: false,
			classNames: {
				off: 'rating_off',
				half: 'rating_half',
				on: 'rating_on',
				selected: 'rating_selected'
			},
			updateUrl: false,
			updateParameterName: 'value',
			afterChange: Prototype.emptyFunction
		};
		Object.extend(this.options,options || {});
		if(this.options.value){
			this.value = this.options.value;
			delete this.options.value;
		}
		if(this.options.input){
			this.options.input = $(this.options.input);
			this.options.input.observe('change',function(input){
				this.setValueFromInput(input);
			}.bind(this,this.options.input));
			this.setValueFromInput(this.options.input,true);
		}
		var range = $R(this.options.min,this.options.max);
		(this.options.reverse ? $A(range).reverse() : range).each(function(i){
			var link = this.buildLink(i);
			this.container.appendChild(link);
			this.links.push(link);
		}.bind(this));
		this.setValue(this.value || this.options.min - 1,false,true);
	},
	buildLink: function(rating){
		var link = $(document.createElement('a'));
		link.value = rating;
		if(this.options.multiple || (!this.options.rated && !this.options.multiple)){
			link.href = '';
			link.onmouseover = this.mouseOver.bind(this,link);
			link.onmouseout = this.mouseOut.bind(this,link);
			link.onclick = this.click.bindAsEventListener(this,link);
		}else{
			link.style.cursor = 'default';
			link.observe('click',function(event){
				Event.stop(event);
				return false;
			}.bindAsEventListener(this));
		}
		link.addClassName(this.options.classNames.off);
		return link;
	},
	disable: function(){
		this.links.each(function(link){
			link.onmouseover = Prototype.emptyFunction;
			link.onmouseout = Prototype.emptyFunction;
			link.onclick = Prototype.emptyFunction;
			link.observe('click',function(event){
				Event.stop(event);
				return false;
			}.bindAsEventListener(this));
			link.style.cursor = 'default';
		}.bind(this));
	},
	setValueFromInput: function(input,prevent_callbacks){
		this.setValue((input.options ? input.options[input.options.selectedIndex].value : input.value),true,prevent_callbacks);
	},
	setValue: function(value,force_selected,prevent_callbacks){
		this.value = value;
		if(this.options.input){
			if(this.options.input.options){
				$A(this.options.input.options).each(function(option,i){
					if(option.value == this.value){
						this.options.input.options.selectedIndex = i;
						throw $break;
					}
				}.bind(this));
			}else
				this.options.input.value = this.value;
		}
		this.render(this.value,force_selected);
		if(!prevent_callbacks){
			if(this.options.updateUrl){
				var params = {};
				params[this.options.updateParameterName] = this.value;
				new Ajax.Request(this.options.updateUrl,{
					parameters: params
				});
			}
			this.notify('afterChange',this.value);
		}
	},
	render: function(rating,force_selected){
		(this.options.reverse ? this.links.reverse() : this.links).each(function(link,i){
			if(link.value <= Math.ceil(rating)){
				link.className = this.options.classNames[link.value <= rating ? 'on' : 'half'];
				if(this.options.rated || force_selected)
					link.addClassName(this.options.classNames.selected);
			}else
				link.className = this.options.classNames.off;
		}.bind(this));
	},
	mouseOver: function(link){
		this.render(link.value,true);
	},
	mouseOut: function(link){
		this.render(this.value);
	},
	click: function(event,link){
		this.options.rated = true;
		this.setValue((link.value ? link.value : link),true);
		if(!this.options.multiple)
			this.disable();
		if(this.options.capture){
			Event.stop(event);
			return false;
		}
	}
});
Object.extend(Control.Rating,{
	instances: [],
	findByElementId: function(id){
		return Control.Rating.instances.find(function(instance){
			return (instance.container.id && instance.container.id == id);
		});
	}
});
Object.Event.extend(Control.Rating);