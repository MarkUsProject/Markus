// jQuery - Smart Poll - Copyright TJ Holowaychuk <tj@vision-media.ca> (MIT Licensed)

;(function($) {

    /**
     * Poll _callback_ with an interval of _ms_. When
     * the retry function is called _callback_ will continue
     * to be invoked while increasing the interval by 50%.
     *
     * The _ms_ argument defaults to 1000 and allows a function in
     * its place like the example below.
     *
     *   $.poll(function(retry){
   *     $.get('something', function(response, status){
   *       if (status == 'success')
   *         // Do something
   *       else
   *         retry()
   *     })
   *   })
     *
     * @param  {int} ms
     * @param  {function} callback
     * @api public
     */

    $.poll = function(ms, callback) {
        if ($.isFunction(ms)) {
            callback = ms
            ms = 1000
        }
        (function retry() {
            setTimeout(function() {
                callback(retry)
            }, ms)
            ms *= 1.5
        })()
    }

})(jQuery);