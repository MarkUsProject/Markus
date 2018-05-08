/** Modal windows, powered by jQuery.easyModal. */
export class ModalMarkus {
  constructor(elem, openLink) {
    this.$elem = $(elem).easyModal(
      {
        onOpen: (myModal) => {
          // Wait for the modal to load
          setTimeout(() => {
            // search for elements that can receive text as input
            let inputs = $(myModal).find('textarea, input:text');
            if (inputs.length > 0) {
              inputs[0].focus();
            }
          }, 200);
        },
        updateZIndexOnOpen: false,
        // This is a hard-coded constant to avoid trampling on
        // z-index values set by browser extensions. See issue #3212.
        'zIndex': function () {
          return 100;
        }
      });
    this.$elem.find('.make_div_clickable, [type=reset]').click(() => {
      // Set callbacks for buttons to close the modal.
      this.close();
    });

    // If link is provided, bind its onclick to open this modal.
    if (openLink !== undefined) {
      $(openLink).click(() => this.open());
    }
  }

  open() {
    this.$elem.trigger('openModal');
  }

  close() {
    this.$elem.trigger('closeModal');
  }
}


$(document).ready(() => {
  $('.dialog').each((_, dialog) => {
    let open_link = dialog.getAttribute('data-open-link') || undefined;
    new ModalMarkus('#' + dialog.id, open_link);
  })
});
