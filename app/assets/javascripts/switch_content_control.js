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

$(document).ready(function() {

    if(LIB.getId1 == null || LIB.getId2 == null){
        return;
    }
    //initially disable yml
    $(LIB.getId2())[0].hidden = true;
    //disable yml (and enable csv) when csv is clicked
    document.getElementById('upload_file_type_csv').addEventListener('click', function() {
        $(LIB.getId1())[0].hidden = false;
        $(LIB.getId2())[0].hidden = true;
    });

    //and vice versa
    document.getElementById('upload_file_type_yml').addEventListener('click', function() {
        $(LIB.getId1())[0].hidden = true;
        $(LIB.getId2())[0].hidden = false;
    });
});
