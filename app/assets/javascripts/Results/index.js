jQuery(document).ready(function () {
    window.modal_download_files = new ModalMarkus('#download_files_dialog');
    modal_download = jQuery('#download_dialog').easyModal();
    jQuery('#downloadModal').on('click',function(){
        modal_download.trigger('openModal');
    });
});