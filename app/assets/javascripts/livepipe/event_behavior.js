/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/extra/event_behavior
 * @require prototype.js, livepipe.js
 * @attribution http://www.adamlogic.com/2007/03/20/3_metaprogramming-javascript-presentation
 */

if(typeof(Prototype) == "undefined")
	throw "Event.Behavior requires Prototype to be loaded.";
if(typeof(Object.Event) == "undefined")
	throw "Event.Behavior requires Object.Event to be loaded.";
	
Event.Behavior = {
	addVerbs: function(verbs){
		for(name in verbs){
			v = new Event.Behavior.Verb(verbs[name]);
			Event.Behavior.Verbs[name] = v;
			Event.Behavior[name.underscore()] = Event.Behavior[name] = v.getCallbackForStack.bind(v);
		}
	},
	addEvents: function(events){
		$H(events).each(function(event_type){
			Event.Behavior.Adjective.prototype[event_type.key.underscore()] = Event.Behavior.Adjective.prototype[event_type.key] = function(){
				this.nextConditionType = 'and';
				this.events.push(event_type.value);
				this.attachObserver(false);
				return this;
			};
		});
	},
	invokeElementMethod: function(element,action,args){
		if(typeof(element) == 'function'){
			return $A(element()).each(function(e){
				if(typeof(args[0]) == 'function'){
					return $A(args[0]).each(function(a){
						return $(e)[action].apply($(e),(a ? [a] : []));
					});
				}else
					return $(e)[action].apply($(e),args || []);
			});
		}else
			return $(element)[action].apply($(element),args || []);
	}
};

Event.Behavior.Verbs = $H({});

Event.Behavior.Verb = Class.create();
Object.extend(Event.Behavior.Verb.prototype,{
	originalAction: false,
	execute: false,
	executeOpposite: false,
	target: false,
	initialize: function(action){
		this.originalAction = action;
		this.execute = function(action,target,argument){
			return (argument)
				? action(target,argument)
				: action(target)
			;
		}.bind(this,action);
	},
	setOpposite: function(opposite_verb){
		opposite_action = opposite_verb.originalAction;
		this.executeOpposite = function(opposite_action,target,argument){
			return (argument)
				? opposite_action(target,argument)
				: opposite_action(target)
			;
		}.bind(this,opposite_action);
	},
	getCallbackForStack: function(argument){
		return new Event.Behavior.Noun(this,argument);
	}
});

Event.Behavior.addVerbs({
	call: function(callback){
		callback();
	},
	show: function(element){
		return Event.Behavior.invokeElementMethod(element,'show');
	},
	hide: function(element){
		return Event.Behavior.invokeElementMethod(element,'hide');
	},
	remove: function(element){
		return Event.Behavior.invokeElementMethod(element,'remove');
	},
	setStyle: function(element,styles){
		return Event.Behavior.invokeElementMethod(element,'setStyle',[(typeof(styles) == 'function' ? styles() : styles)]);
	},
	addClassName: function(element,class_name){
		return Event.Behavior.invokeElementMethod(element,'addClassName',[(typeof(class_name) == 'function' ? class_name() : class_name)]);
	},
	removeClassName: function(element,class_name){
		return Event.Behavior.invokeElementMethod(element,'removeClassName',[(typeof(class_name) == 'function' ? class_name() : class_name)]);
	},
	setClassName: function(element,class_name){
		c = (typeof(class_name) == 'function') ? class_name() : class_name;
		if(typeof(element) == 'function'){
			return $A(element()).each(function(e){
				$(e).className = c;
			});
		}else
			return $(element).className = c;
	},
	update: function(content,element){
		return Event.Behavior.invokeElementMethod(element,'update',[(typeof(content) == 'function' ? content() : content)]);
	},
	replace: function(content,element){
		return Event.Behavior.invokeElementMethod(element,'replace',[(typeof(content) == 'function' ? content() : content)]);
	}
});
Event.Behavior.Verbs.show.setOpposite(Event.Behavior.Verbs.hide);
Event.Behavior.Verbs.hide.setOpposite(Event.Behavior.Verbs.show);
Event.Behavior.Verbs.addClassName.setOpposite(Event.Behavior.Verbs.removeClassName);
Event.Behavior.Verbs.removeClassName.setOpposite(Event.Behavior.Verbs.addClassName);

Event.Behavior.Noun = Class.create();
Object.extend(Event.Behavior.Noun.prototype,{
	verbs: false,
	verb: false,
	argument: false,
	subject: false,
	target: false,
	initialize: function(verb,argument){
		//this.verbs = $A([]);
		this.verb = verb;
		this.argument = argument;
	},
	execute: function(){
		return (this.target)
			? this.verb.execute(this.target,this.argument)
			: this.verb.execute(this.argument)
		;
	},
	executeOpposite: function(){
		return (this.target)
			? this.verb.executeOpposite(this.target,this.argument)
			: this.verb.executeOpposite(this.argument)
		;
	},
	when: function(subject){
		this.subject = subject;
		return new Event.Behavior.Adjective(this);
	},
	getValue: function(){
		return Try.these(
			function(){return $(this.subject).getValue();}.bind(this),
			function(){return $(this.subject).options[$(this.subject).options.selectedIndex].value;}.bind(this),
			function(){return $(this.subject).value;}.bind(this),
			function(){return $(this.subject).innerHTML;}.bind(this)
		);
	},
	containsValue: function(match){
		value = this.getValue();
		if(typeof(match) == 'function'){
			return $A(match()).include(value);
		}else
			return value.match(match);
	},
	setTarget: function(target){
		this.target = target;
		return this;
	},
	and: function(){

	}
});
Event.Behavior.Noun.prototype._with = Event.Behavior.Noun.prototype.setTarget;
Event.Behavior.Noun.prototype.on = Event.Behavior.Noun.prototype.setTarget;
Event.Behavior.Noun.prototype.of = Event.Behavior.Noun.prototype.setTarget;
Event.Behavior.Noun.prototype.to = Event.Behavior.Noun.prototype.setTarget;
Event.Behavior.Noun.prototype.from = Event.Behavior.Noun.prototype.setTarget;

Event.Behavior.Adjective = Class.create();
Object.extend(Event.Behavior.Adjective.prototype,{
	noun: false,
	lastConditionName: '',
	nextConditionType: 'and',
	conditions: $A([]),
	events: $A([]),
	attached: false,
	initialize: function(noun){
		this.conditions = $A([]);
		this.events = $A([]);
		this.noun = noun;
	},
	attachObserver: function(execute_on_load){
		if(this.attached){
			//this may call things multiple times, but is the only way to gaurentee correct state on startup
			if(execute_on_load)
				this.execute();
			return;
		}
		this.attached = true;
		if(typeof(this.noun.subject) == 'function'){
			$A(this.noun.subject()).each(function(subject){
				(this.events.length > 0 ? this.events : $A(['change'])).each(function(event_name){
					(subject.observe ? subject : $(subject)).observe(event_name,function(){
						this.execute();
					}.bind(this));
				}.bind(this));
			}.bind(this));
		}else{
			(this.events.length > 0 ? this.events : $A(['change'])).each(function(event_name){
				$(this.noun.subject).observe(event_name,function(){
					this.execute();
				}.bind(this));
			}.bind(this));
		}
		if(execute_on_load)
			this.execute();
	},
	execute: function(){
		if(this.match())
			return this.noun.execute();
		else if(this.noun.verb.executeOpposite)
			this.noun.executeOpposite();
	},
	attachCondition: function(callback){
		this.conditions.push([this.nextConditionType,callback.bind(this)]);
	},
	match: function(){
		if(this.conditions.length == 0)
			return true;
		else{
			return this.conditions.inject(new Boolean(),function(bool,condition){
				return (condition[0] == 'and') ? (bool && condition[1]()) : (bool || condition[1]());
			});
		}
	},
	//conditions
	is: function(item){
		this.lastConditionName = 'is';
		this.attachCondition(function(item){
			return (typeof(item) == 'function' ? item() : item) == this.noun.getValue();
		}.bind(this,item));
		this.attachObserver(true);
		return this;
	},
	isNot: function(item){
		this.lastConditionName = 'isNot';
		this.attachCondition(function(item){
			return (typeof(item) == 'function' ? item() : item) != this.noun.getValue();
		}.bind(this,item));
		this.attachObserver(true);
		return this;
	},
	contains: function(item){
		this.lastConditionName = 'contains';
		this.attachCondition(function(item){
			return this.noun.containsValue(item);
		}.bind(this,item));
		this.attachObserver(true);
		return this;
	},
	within: function(item){
		this.lastConditionName = 'within';
		this.attachCondition(function(item){
			
		}.bind(this,item));
		this.attachObserver(true);
		return this;
	},
	//events
	change: function(){
		this.nextConditionType = 'and';
		this.attachObserver(true);
		return this;
	},
	and: function(condition){
		this.attached = false;
		this.nextConditionType = 'and';
		if(condition)
			this[this.lastConditionName](condition);
		return this;
	},
	or: function(condition){
		this.attached = false;
		this.nextConditionType = 'or';
		if(condition)
			this[this.lastConditionName](condition);
		return this;
	}
});

Event.Behavior.addEvents({
	losesFocus: 'blur',
	gainsFocus: 'focus',
	isClicked: 'click',
	isDoubleClicked: 'dblclick',
	keyPressed: 'keypress'
});

Event.Behavior.Adjective.prototype.is_not = Event.Behavior.Adjective.prototype.isNot;
Event.Behavior.Adjective.prototype.include = Event.Behavior.Adjective.prototype.contains;
Event.Behavior.Adjective.prototype.includes = Event.Behavior.Adjective.prototype.contains;
Event.Behavior.Adjective.prototype.are = Event.Behavior.Adjective.prototype.is;
Event.Behavior.Adjective.prototype.areNot = Event.Behavior.Adjective.prototype.isNot;
Event.Behavior.Adjective.prototype.are_not = Event.Behavior.Adjective.prototype.isNot;
Event.Behavior.Adjective.prototype.changes = Event.Behavior.Adjective.prototype.change;