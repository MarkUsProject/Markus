const FLASH_KEYS = ['notice', 'warning', 'success', 'error'];


export function setUpCallbacks(elem) {
  elem.addEventListener('ajax:complete', renderFlash);
  elem.addEventListener('ajax:beforeSend', hideFlash);
}


/*
 * Display flash messages sent in response to an AJAX request.
 */
export function renderFlash(event, request) {
  // For rails-ujs, request is stored in event.
  if (request === undefined) {
    request = event.detail[0];
  }
  FLASH_KEYS.forEach((key) => {
    const flashMessage = request.getResponseHeader(`X-Message-${key}`);
    const flashDiv = document.getElementsByClassName(key)[0];
    if (!flashMessage || flashDiv === undefined) {
      return;
    }
    const messages = flashMessage.split(';');
    messages.forEach(message => {
      const contents = flashDiv.getElementsByClassName('flash-content')[0] || flashDiv;
      contents.insertAdjacentHTML('beforeend', message);
    });
    flashDiv.style.display = '';
  });
}


/*
 * Hide all flash message divs. Typically used when a new non-GET request is sent.
 */
export function hideFlash() {
  FLASH_KEYS.forEach((key) => {
    for (let elem of document.getElementsByClassName(key)) {
      elem.style.display = 'none';
      const contents = elem.getElementsByClassName('flash-content')[0] || elem;
      contents.innerHTML = '';
    }
  });
}


/*
 * Register global callbacks for both rails-ujs and jQuery.
 */
document.addEventListener('DOMContentLoaded', () => {
  let elem = document.body;
  elem.addEventListener('ajax:complete', renderFlash);

  elem.addEventListener('ajax:beforeSend', (event) => {
    const settings = event.detail[1];
    if (settings.type.toUpperCase() !== 'GET') {
      hideFlash();
    }
  });
});


$(document).ajaxSend((event, request, settings) => {
  if (settings.type.toUpperCase() !== 'GET') {
    hideFlash();
  }
});


$(document).ajaxComplete(renderFlash);
