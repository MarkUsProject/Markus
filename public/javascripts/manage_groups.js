function toggle_groups_selection(groupings_all){
    if(groupings_all) {
         $$('#groups tbody input').each(function(e){
	   e.setValue(true);
	   }
	 );
    }else{
         $$('#groups tbody input').each(function(e){
	    e.setValue(false);
	    }
	 );
    }
}

function toggle_groupings_not_valid(){
   $('working').show();
   $$('#groups tr').each(function(e){
      e.show();
   });
   $$('.grouping_not_valid').each(function(e){
     e.hide();
   });
   $('working').hide();
}

function toggle_groupings_valid(){
   $('working').show();
   $$('#groups tr').each(function(e){
      e.show();
   });

   $$('.grouping_valid').each(function(e){
     e.hide();
   })

   $('working').hide();
}

function toggle_groupings_assigned(){
   $('working').show();
   $$('#groups tr').each(function(e){
      e.show();
   });
   $$('.assigned').each(function(e){
     e.hide();
   });
   $('working').hide();
}

function toggle_groupings_unassigned(){
   $('working').show();
   $$('#groups tr').each(function(e){
      e.show();
   });
   $$('.unassigned').each(function(e){
     e.hide();
   });
   $('working').hide();
}

function toggle_groupings_all(){
   $('working').show();
   $$('#groups tr').each(function(e){
      e.show();
   });
  ($)
}
