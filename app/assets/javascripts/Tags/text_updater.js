function updateCharCount(textID, infoID, numChar){
    //Gets the text area element
    var length = textID.value.length;

    //Next, changes the value.
    infoID.innerHTML = length + "/" + numChar;
}
