var LIB = LIB || (function(){
    var _args = {}; // private

    return {
        init : function(Args) {
            _args = Args;
        },
        getId1 : function() {
            return _args[0];
        },
        getId2 : function() {
            return _args[1];
        }
    };
}());

jQuery(document).ready(function() {

    if(LIB.getId1 == null || LIB.getId2 == null){
        return;
    }
    //initially disable yml
    jQuery(LIB.getId2())[0].hidden = true;
    //disable yml (and enable csv) when csv is clicked
    document.getElementById('upload_file_type_csv').addEventListener('click', function() {
        jQuery(LIB.getId1())[0].hidden = false;
        jQuery(LIB.getId2())[0].hidden = true;
    });

    //and vice versa
    document.getElementById('upload_file_type_yml').addEventListener('click', function() {
        jQuery(LIB.getId1())[0].hidden = true;
        jQuery(LIB.getId2())[0].hidden = false;
    });
});
