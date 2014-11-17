function remove_tag(tagID)
{
    //First, we get the span element that has the current tag.
    var tag = document.getElementById(tagID);

    //TODO: Implement tag removal features.

    //Next, we remove the tag from the div.
    document.getElementById('active_tags').removeAttribute(tagID);

}