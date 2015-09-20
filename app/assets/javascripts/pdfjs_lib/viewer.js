/* -*- Mode: Java; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/* vim: set shiftwidth=2 tabstop=2 autoindent cindent expandtab: */
/* Copyright 2012 Mozilla Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/* globals PDFJS, PDFBug, FirefoxCom, Stats, Cache, ProgressBar,
           DownloadManager, getFileName, scrollIntoView, getPDFFileNameFromURL,
           Preferences, SidebarView, ViewHistory, PageView,
           ThumbnailView, URL, noContextMenuHandler,
           PasswordPrompt, HandTool, Promise,
           DocumentProperties, DocumentOutlineView, DocumentAttachmentsView */

'use strict';

var DEFAULT_SCALE = 'auto';
var DEFAULT_SCALE_DELTA = 1.1;
var UNKNOWN_SCALE = 0;
var DEFAULT_CACHE_SIZE = 10;
var CSS_UNITS = 96.0 / 72.0;
var SCROLLBAR_PADDING = 40;
var VERTICAL_PADDING = 5;
var MAX_AUTO_SCALE = 1.25;
var MIN_SCALE = 0.25;
var MAX_SCALE = 10.0;
var VIEW_HISTORY_MEMORY = 20;
var SCALE_SELECT_CONTAINER_PADDING = 8;
var SCALE_SELECT_PADDING = 22;
var THUMBNAIL_SCROLL_MARGIN = -19;
var CLEANUP_TIMEOUT = 30000;
var IGNORE_CURRENT_POSITION_ON_ZOOM = false;

var PresentationMode = {active: false};

var RenderingStates = {
  INITIAL: 0,
  RUNNING: 1,
  PAUSED: 2,
  FINISHED: 3
};
var FindStates = {
  FIND_FOUND: 0,
  FIND_NOTFOUND: 1,
  FIND_WRAPPED: 2,
  FIND_PENDING: 3
};

PDFJS.imageResourcesPath = '/assets/pdfjs';

var mozL10n = document.mozL10n || document.webL10n;

var cache = new Cache(DEFAULT_CACHE_SIZE);
var currentPageNumber = 1;

var PDFView = {
  pages: [],
  thumbnails: [],
  currentScale: UNKNOWN_SCALE,
  currentScaleValue: null,
  initialBookmark: document.location.hash.substring(1),
  container: null,
  thumbnailContainer: null,
  initialized: false,
  fellback: false,
  pdfDocument: null,
  sidebarOpen: false,
  printing: false,
  pageViewScroll: null,
  thumbnailViewScroll: null,
  pageRotation: 0,
  mouseScrollTimeStamp: 0,
  mouseScrollDelta: 0,
  lastScroll: 0,
  previousPageNumber: 1,
  isViewerEmbedded: (window.parent !== window),
  idleTimeout: null,
  currentPosition: null,
  url: '',
  onLoadComplete: function() {},
  onPageRendered: function(page, pageNum) {},

  // called once when the document is loaded
  initialize: function pdfViewInitialize() {

    var self = this;
    var container = this.container = document.getElementById('viewerContainer');
    this.pageViewScroll = {};
    this.watchScroll(container, this.pageViewScroll, updateViewarea);

    Preferences.initialize();

    DocumentProperties.initialize({
      overlayName: 'documentPropertiesOverlay',
      closeButton: document.getElementById('documentPropertiesClose'),
      fileNameField: document.getElementById('fileNameField'),
      fileSizeField: document.getElementById('fileSizeField'),
      titleField: document.getElementById('titleField'),
      authorField: document.getElementById('authorField'),
      subjectField: document.getElementById('subjectField'),
      keywordsField: document.getElementById('keywordsField'),
      creationDateField: document.getElementById('creationDateField'),
      modificationDateField: document.getElementById('modificationDateField'),
      creatorField: document.getElementById('creatorField'),
      producerField: document.getElementById('producerField'),
      versionField: document.getElementById('versionField'),
      pageCountField: document.getElementById('pageCountField')
    });

    container.addEventListener('scroll', function() {
      self.lastScroll = Date.now();
    }, false);

    var initializedPromise = Promise.all([
      Preferences.get('enableWebGL').then(function resolved(value) {
        PDFJS.disableWebGL = !value;
      }),
      /*Preferences.get('sidebarViewOnLoad').then(function resolved(value) {
        self.preferenceSidebarViewOnLoad = value;
      }),*/
      Preferences.get('pdfBugEnabled').then(function resolved(value) {
        self.preferencesPdfBugEnabled = value;
      }),
      Preferences.get('disableTextLayer').then(function resolved(value) {
        if (PDFJS.disableTextLayer === true) {
          return;
        }
        PDFJS.disableTextLayer = value;
      }),
      Preferences.get('disableRange').then(function resolved(value) {
        if (PDFJS.disableRange === true) {
          return;
        }
        PDFJS.disableRange = value;
      }),
      Preferences.get('disableAutoFetch').then(function resolved(value) {
        PDFJS.disableAutoFetch = value;
      }),
      Preferences.get('disableFontFace').then(function resolved(value) {
        if (PDFJS.disableFontFace === true) {
          return;
        }
        PDFJS.disableFontFace = value;
      }),
      Preferences.get('useOnlyCssZoom').then(function resolved(value) {
        PDFJS.useOnlyCssZoom = value;
      })
      // TODO move more preferences and other async stuff here
    ]).catch(function (reason) { });

    return initializedPromise.then(function () {
      PDFView.initialized = true;
    });
  },

  getPage: function pdfViewGetPage(n) {
    var page = this.pdfDocument.getPage(n);

    this.onPageRendered(page, n);

    return page;
  },

  // Helper function to keep track whether a div was scrolled up or down and
  // then call a callback.
  watchScroll: function pdfViewWatchScroll(viewAreaElement, state, callback) {
    state.down = true;
    state.lastY = viewAreaElement.scrollTop;
    state.rAF = null;
    viewAreaElement.addEventListener('scroll', function debounceScroll(evt) {
      if (state.rAF) {
        return;
      }
      // schedule an invocation of webViewerScrolled for next animation frame.
      state.rAF = window.requestAnimationFrame(function webViewerScrolled() {
        state.rAF = null;
        if (!PDFView.pdfDocument) {
          return;
        }
        var currentY = viewAreaElement.scrollTop;
        var lastY = state.lastY;
        if (currentY > lastY) {
          state.down = true;
        } else if (currentY < lastY) {
          state.down = false;
        }
        // else do nothing and use previous value
        state.lastY = currentY;
        callback();
      });
    }, true);
  },

  _setScaleUpdatePages: function pdfView_setScaleUpdatePages(
      newScale, newValue, resetAutoSettings, noScroll) {
    this.currentScaleValue = newValue;
    if (newScale === this.currentScale) {
      return;
    }
    for (var i = 0, ii = this.pages.length; i < ii; i++) {
      this.pages[i].update(newScale);
    }
    this.currentScale = newScale;

    if (!noScroll) {
      var page = this.page, dest;
      if (this.currentPosition && !IGNORE_CURRENT_POSITION_ON_ZOOM) {
        page = this.currentPosition.page;
        dest = [null, { name: 'XYZ' }, this.currentPosition.left,
                this.currentPosition.top, null];
      }
      this.pages[page - 1].scrollIntoView(dest);
    }
    var event = document.createEvent('UIEvents');
    event.initUIEvent('scalechange', false, false, window, 0);
    event.scale = newScale;
    event.resetAutoSettings = resetAutoSettings;
    window.dispatchEvent(event);
  },

  setScale: function pdfViewSetScale(value, resetAutoSettings, noScroll) {
    if (value === 'custom') {
      return;
    }
    var scale = parseFloat(value);

    if (scale > 0) {
      this._setScaleUpdatePages(scale, value, true, noScroll);
    } else {
      var currentPage = this.pages[this.page - 1];
      if (!currentPage) {
        return;
      }
      var hPadding = PresentationMode.active ? 0 : SCROLLBAR_PADDING;
      var vPadding = PresentationMode.active ? 0 : VERTICAL_PADDING;
      var pageWidthScale = (this.container.clientWidth - hPadding) /
                            currentPage.width * currentPage.scale;
      var pageHeightScale = (this.container.clientHeight - vPadding) /
                             currentPage.height * currentPage.scale;
      switch (value) {
        case 'page-actual':
          scale = 1;
          break;
        case 'page-width':
          scale = pageWidthScale;
          break;
        case 'page-height':
          scale = pageHeightScale;
          break;
        case 'page-fit':
          scale = Math.min(pageWidthScale, pageHeightScale);
          break;
        case 'auto':
          var isLandscape = (currentPage.width > currentPage.height);
          var horizontalScale = isLandscape ? pageHeightScale : pageWidthScale;
          scale = Math.min(MAX_AUTO_SCALE, horizontalScale);
          break;
        default:
          console.error('pdfViewSetScale: \'' + value +
                        '\' is an unknown zoom value.');
          return;
      }
      this._setScaleUpdatePages(scale, value, resetAutoSettings, noScroll);

      selectScaleOption(value);
    }
    window.annotation_manager.selectionBox = {};
  },

  zoomIn: function pdfViewZoomIn(ticks) {
    var newScale = this.currentScale;
    do {
      newScale = (newScale * DEFAULT_SCALE_DELTA).toFixed(2);
      newScale = Math.ceil(newScale * 10) / 10;
      newScale = Math.min(MAX_SCALE, newScale);
    } while (--ticks && newScale < MAX_SCALE);

    this.setScale(newScale, true);
  },

  zoomOut: function pdfViewZoomOut(ticks) {
    var newScale = this.currentScale;
    do {
      newScale = (newScale / DEFAULT_SCALE_DELTA).toFixed(2);
      newScale = Math.floor(newScale * 10) / 10;
      newScale = Math.max(MIN_SCALE, newScale);
    } while (--ticks && newScale > MIN_SCALE);
    this.setScale(newScale, true);
  },

  set page(val) {
    var pages = this.pages;
    var event = document.createEvent('UIEvents');
    event.initUIEvent('pagechange', false, false, window, 0);

    if (!(0 < val && val <= pages.length)) {
      this.previousPageNumber = val;
      event.pageNumber = this.page;
      window.dispatchEvent(event);
      return;
    }

    pages[val - 1].updateStats();
    this.previousPageNumber = currentPageNumber;
    currentPageNumber = val;
    event.pageNumber = val;
    window.dispatchEvent(event);

    // checking if the this.page was called from the updateViewarea function:
    // avoiding the creation of two "set page" method (internal and public)
    if (updateViewarea.inProgress) {
      return;
    }
    // Avoid scrolling the first page during loading
    if (this.loading && val === 1) {
      return;
    }
    pages[val - 1].scrollIntoView();
  },

  get page() {
    return currentPageNumber;
  },

  get supportsPrinting() {
    var canvas = document.createElement('canvas');
    var value = 'mozPrintCallback' in canvas;
    // shadow
    Object.defineProperty(this, 'supportsPrinting', { value: value,
                                                      enumerable: true,
                                                      configurable: true,
                                                      writable: false });
    return value;
  },

  get supportsFullscreen() {
    var doc = document.documentElement;
    var support = doc.requestFullscreen || doc.mozRequestFullScreen ||
                  doc.webkitRequestFullScreen || doc.msRequestFullscreen;

    if (document.fullscreenEnabled === false ||
        document.mozFullScreenEnabled === false ||
        document.webkitFullscreenEnabled === false ||
        document.msFullscreenEnabled === false) {
      support = false;
    }

    Object.defineProperty(this, 'supportsFullscreen', { value: support,
                                                        enumerable: true,
                                                        configurable: true,
                                                        writable: false });
    return support;
  },

  get supportsIntegratedFind() {
    var support = false;
    Object.defineProperty(this, 'supportsIntegratedFind', { value: support,
                                                            enumerable: true,
                                                            configurable: true,
                                                            writable: false });
    return support;
  },

  get supportsDocumentFonts() {
    var support = true;

    Object.defineProperty(this, 'supportsDocumentFonts', { value: support,
                                                           enumerable: true,
                                                           configurable: true,
                                                           writable: false });
    return support;
  },

  get supportsDocumentColors() {
    var support = true;

    Object.defineProperty(this, 'supportsDocumentColors', { value: support,
                                                            enumerable: true,
                                                            configurable: true,
                                                            writable: false });
    return support;
  },

  get loadingBar() {
    var bar = new ProgressBar('#loadingBar', {});
    Object.defineProperty(this, 'loadingBar', { value: bar,
                                                enumerable: true,
                                                configurable: true,
                                                writable: false });
    return bar;
  },

  get isHorizontalScrollbarEnabled() {
    return (PresentationMode.active ? false :
            (this.container.scrollWidth > this.container.clientWidth));
  },

  initPassiveLoading: function pdfViewInitPassiveLoading() {
    var pdfDataRangeTransportReadyResolve;
    var pdfDataRangeTransportReady = new Promise(function (resolve) {
      pdfDataRangeTransportReadyResolve = resolve;
    });
    var pdfDataRangeTransport = {
      rangeListeners: [],
      progressListeners: [],
      progressiveReadListeners: [],
      ready: pdfDataRangeTransportReady,

      addRangeListener: function PdfDataRangeTransport_addRangeListener(
                                   listener) {
        this.rangeListeners.push(listener);
      },

      addProgressListener: function PdfDataRangeTransport_addProgressListener(
                                      listener) {
        this.progressListeners.push(listener);
      },

      addProgressiveReadListener:
          function PdfDataRangeTransport_addProgressiveReadListener(listener) {
        this.progressiveReadListeners.push(listener);
      },

      onDataRange: function PdfDataRangeTransport_onDataRange(begin, chunk) {
        var listeners = this.rangeListeners;
        for (var i = 0, n = listeners.length; i < n; ++i) {
          listeners[i](begin, chunk);
        }
      },

      onDataProgress: function PdfDataRangeTransport_onDataProgress(loaded) {
        this.ready.then(function () {
          var listeners = this.progressListeners;
          for (var i = 0, n = listeners.length; i < n; ++i) {
            listeners[i](loaded);
          }
        }.bind(this));
      },

      onDataProgressiveRead:
          function PdfDataRangeTransport_onDataProgress(chunk) {
        this.ready.then(function () {
          var listeners = this.progressiveReadListeners;
          for (var i = 0, n = listeners.length; i < n; ++i) {
            listeners[i](chunk);
          }
        }.bind(this));
      },

      transportReady: function PdfDataRangeTransport_transportReady() {
        pdfDataRangeTransportReadyResolve();
      },

      requestDataRange: function PdfDataRangeTransport_requestDataRange(
                                  begin, end) {
        FirefoxCom.request('requestDataRange', { begin: begin, end: end });
      }
    };

    window.addEventListener('message', function windowMessage(e) {
      if (e.source !== null) {
        // The message MUST originate from Chrome code.
        console.warn('Rejected untrusted message from ' + e.origin);
        return;
      }
      var args = e.data;

      if (typeof args !== 'object' || !('pdfjsLoadAction' in args)) {
        return;
      }
      switch (args.pdfjsLoadAction) {
        case 'supportsRangedLoading':
          PDFView.open(args.pdfUrl, 0, undefined, pdfDataRangeTransport, {
            length: args.length,
            initialData: args.data
          });
          break;
        case 'range':
          pdfDataRangeTransport.onDataRange(args.begin, args.chunk);
          break;
        case 'rangeProgress':
          pdfDataRangeTransport.onDataProgress(args.loaded);
          break;
        case 'progressiveRead':
          pdfDataRangeTransport.onDataProgressiveRead(args.chunk);
          break;
        case 'progress':
          PDFView.progress(args.loaded / args.total);
          break;
        case 'complete':
          if (!args.data) {
            PDFView.error(mozL10n.get('loading_error', null,
                          'An error occurred while loading the PDF.'), e);
            break;
          }
          PDFView.open(args.data, 0);
          break;
      }
    });
    FirefoxCom.requestSync('initPassiveLoading', null);
  },

  close: function pdfViewClose() {
    var errorWrapper = document.getElementById('errorWrapper');
    errorWrapper.setAttribute('hidden', 'true');

    if (!this.pdfDocument) {
      return;
    }

    this.pdfDocument.destroy();
    this.pdfDocument = null;

    var container = document.getElementById('viewer');
    while (container.hasChildNodes()) {
      container.removeChild(container.lastChild);
    }

    if (typeof PDFBug !== 'undefined') {
      PDFBug.cleanup();
    }
  },

  // TODO(mack): This function signature should really be pdfViewOpen(url, args)
  open: function pdfViewOpen(file, scale, password,
                             pdfDataRangeTransport, args) {
    if (this.pdfDocument) {
      // Reload the preferences if a document was previously opened.
      Preferences.reload();
    }
    this.close();

    var parameters = {password: password};
    if (typeof file === 'string') { // URL
      parameters.url = file;
    } else if (file && 'byteLength' in file) { // ArrayBuffer
      parameters.data = file;
    } else if (file.url && file.originalUrl) {
      parameters.url = file.url;
    }
    if (args) {
      for (var prop in args) {
        parameters[prop] = args[prop];
      }
    }

    var self = this;
    self.loading = true;
    self.downloadComplete = false;

    var passwordNeeded = function passwordNeeded(updatePassword, reason) {
      PasswordPrompt.updatePassword = updatePassword;
      PasswordPrompt.reason = reason;
      PasswordPrompt.open();
    };

    function getDocumentProgress(progressData) {
      self.progress(progressData.loaded / progressData.total);
    }

    PDFJS.getDocument(parameters, pdfDataRangeTransport, passwordNeeded,
                      getDocumentProgress).then(
      function getDocumentCallback(pdfDocument) {
        self.load(pdfDocument, scale);
        self.loading = false;
      },

      function getDocumentError(exception) {
        var message = exception && exception.message;
        var loadingErrorMessage = mozL10n.get('loading_error', null,
          'An error occurred while loading the PDF.');

        if (exception instanceof PDFJS.InvalidPDFException) {
          // change error message also for other builds
          loadingErrorMessage = mozL10n.get('invalid_file_error', null,
                                            'Invalid or corrupted PDF file.');
        } else if (exception instanceof PDFJS.MissingPDFException) {
          // special message for missing PDF's
          loadingErrorMessage = mozL10n.get('missing_file_error', null,
                                            'Missing PDF file.');
        } else if (exception instanceof PDFJS.UnexpectedResponseException) {
          loadingErrorMessage = mozL10n.get('unexpected_response_error', null,
                                            'Unexpected server response.');
        }

        var moreInfo = {
          message: message
        };
        self.error(loadingErrorMessage, moreInfo);
        self.loading = false;
      }
    );

    if (args && args.length) {
      DocumentProperties.setFileSize(args.length);
    }
  },

  download: function pdfViewDownload() {
    function downloadByUrl() {
      downloadManager.downloadUrl(url, filename);
    }

    var url = this.url.split('#')[0];
    var filename = getPDFFileNameFromURL(url);
    var downloadManager = new DownloadManager();
    downloadManager.onerror = function (err) {
      // This error won't really be helpful because it's likely the
      // fallback won't work either (or is already open).
      PDFView.error('PDF failed to download.');
    };

    if (!this.pdfDocument) { // the PDF is not ready yet
      downloadByUrl();
      return;
    }

    if (!this.downloadComplete) { // the PDF is still downloading
      downloadByUrl();
      return;
    }

    this.pdfDocument.getData().then(
      function getDataSuccess(data) {
        var blob = PDFJS.createBlob(data, 'application/pdf');
        downloadManager.download(blob, url, filename);
      },
      downloadByUrl // Error occurred try downloading with just the url.
    ).then(null, downloadByUrl);
  },

  fallback: function pdfViewFallback(featureId) {
    // Handle any unsupported PDF View features as needed.
  },

  navigateTo: function pdfViewNavigateTo(dest) {
    var destString = '';
    var self = this;

    var goToDestination = function(destRef) {
      self.pendingRefStr = null;
      // dest array looks like that: <page-ref> </XYZ|FitXXX> <args..>
      var pageNumber = destRef instanceof Object ?
        self.pagesRefMap[destRef.num + ' ' + destRef.gen + ' R'] :
        (destRef + 1);
      if (pageNumber) {
        if (pageNumber > self.pages.length) {
          pageNumber = self.pages.length;
        }
        var currentPage = self.pages[pageNumber - 1];
        currentPage.scrollIntoView(dest);
      } else {
        self.pdfDocument.getPageIndex(destRef).then(function (pageIndex) {
          var pageNum = pageIndex + 1;
          self.pagesRefMap[destRef.num + ' ' + destRef.gen + ' R'] = pageNum;
          goToDestination(destRef);
        });
      }
    };

    this.destinationsPromise.then(function() {
      if (typeof dest === 'string') {
        destString = dest;
        dest = self.destinations[dest];
      }
      if (!(dest instanceof Array)) {
        return; // invalid destination
      }
      goToDestination(dest[0]);
    });
  },

  getDestinationHash: function pdfViewGetDestinationHash(dest) {
    if (typeof dest === 'string') {
      return PDFView.getAnchorUrl('#' + escape(dest));
    }
    if (dest instanceof Array) {
      var destRef = dest[0]; // see navigateTo method for dest format
      var pageNumber = destRef instanceof Object ?
        this.pagesRefMap[destRef.num + ' ' + destRef.gen + ' R'] :
        (destRef + 1);
      if (pageNumber) {
        var pdfOpenParams = PDFView.getAnchorUrl('#page=' + pageNumber);
        var destKind = dest[1];
        if (typeof destKind === 'object' && 'name' in destKind &&
            destKind.name === 'XYZ') {
          var scale = (dest[4] || this.currentScaleValue);
          var scaleNumber = parseFloat(scale);
          if (scaleNumber) {
            scale = scaleNumber * 100;
          }
          pdfOpenParams += '&zoom=' + scale;
          if (dest[2] || dest[3]) {
            pdfOpenParams += ',' + (dest[2] || 0) + ',' + (dest[3] || 0);
          }
        }
        return pdfOpenParams;
      }
    }
    return '';
  },

  /**
   * Prefix the full url on anchor links to make sure that links are resolved
   * relative to the current URL instead of the one defined in <base href>.
   * @param {String} anchor The anchor hash, including the #.
   */
  getAnchorUrl: function getAnchorUrl(anchor) {
//#if (GENERIC || B2G)
    return anchor;
//#endif
//#if (FIREFOX || MOZCENTRAL)
//  return this.url.split('#')[0] + anchor;
//#endif
//#if CHROME
//  return location.href.split('#')[0] + anchor;
//#endif
  },

  /**
   * Show the error box.
   * @param {String} message A message that is human readable.
   * @param {Object} moreInfo (optional) Further information about the error
   *                            that is more technical.  Should have a 'message'
   *                            and optionally a 'stack' property.
   */
  error: function pdfViewError(message, moreInfo) {
    var moreInfoText = mozL10n.get('error_version_info',
      {version: PDFJS.version || '?', build: PDFJS.build || '?'},
      'PDF.js v{{version}} (build: {{build}})') + '\n';
    if (moreInfo) {
      moreInfoText +=
        mozL10n.get('error_message', {message: moreInfo.message},
        'Message: {{message}}');
      if (moreInfo.stack) {
        moreInfoText += '\n' +
          mozL10n.get('error_stack', {stack: moreInfo.stack},
          'Stack: {{stack}}');
      } else {
        if (moreInfo.filename) {
          moreInfoText += '\n' +
            mozL10n.get('error_file', {file: moreInfo.filename},
            'File: {{file}}');
        }
        if (moreInfo.lineNumber) {
          moreInfoText += '\n' +
            mozL10n.get('error_line', {line: moreInfo.lineNumber},
            'Line: {{line}}');
        }
      }
    }

//#if !(FIREFOX || MOZCENTRAL)
    var errorWrapper = document.getElementById('errorWrapper');
    errorWrapper.removeAttribute('hidden');

    var errorMessage = document.getElementById('errorMessage');
    errorMessage.textContent = message;

    var closeButton = document.getElementById('errorClose');
    closeButton.onclick = function() {
      errorWrapper.setAttribute('hidden', 'true');
    };

    var errorMoreInfo = document.getElementById('errorMoreInfo');
    var moreInfoButton = document.getElementById('errorShowMore');
    var lessInfoButton = document.getElementById('errorShowLess');
    moreInfoButton.onclick = function() {
      errorMoreInfo.removeAttribute('hidden');
      moreInfoButton.setAttribute('hidden', 'true');
      lessInfoButton.removeAttribute('hidden');
      errorMoreInfo.style.height = errorMoreInfo.scrollHeight + 'px';
    };
    lessInfoButton.onclick = function() {
      errorMoreInfo.setAttribute('hidden', 'true');
      moreInfoButton.removeAttribute('hidden');
      lessInfoButton.setAttribute('hidden', 'true');
    };
    moreInfoButton.oncontextmenu = noContextMenuHandler;
    lessInfoButton.oncontextmenu = noContextMenuHandler;
    closeButton.oncontextmenu = noContextMenuHandler;
    moreInfoButton.removeAttribute('hidden');
    lessInfoButton.setAttribute('hidden', 'true');
    errorMoreInfo.value = moreInfoText;
//#else
//  console.error(message + '\n' + moreInfoText);
//  this.fallback();
//#endif
  },

  progress: function pdfViewProgress(level) {
    var percent = Math.round(level * 100);
    // When we transition from full request to range requests, it's possible
    // that we discard some of the loaded data. This can cause the loading
    // bar to move backwards. So prevent this by only updating the bar if it
    // increases.
    if (percent > PDFView.loadingBar.percent || isNaN(percent)) {
      PDFView.loadingBar.percent = percent;
    }
  },

  load: function pdfViewLoad(pdfDocument, scale) {
    var self = this;
    var isOnePageRenderedResolved = false;
    var resolveOnePageRendered = null;

    var onePageRendered = new Promise(function (resolve) {
      resolveOnePageRendered = resolve;
    });

    this.pdfDocument = pdfDocument;

    DocumentProperties.resolveDataAvailable();

    var downloadedPromise = pdfDocument.getDownloadInfo().then(function() {
      self.downloadComplete = true;
      PDFView.loadingBar.hide();
      var outerContainer = document.getElementById('outerContainer');
      outerContainer.classList.remove('loadingInProgress');
    });


    var pagesCount = pdfDocument.numPages;

    var id = pdfDocument.fingerprint;
    document.getElementById('numPages').textContent =
      mozL10n.get('page_of', {pageCount: pagesCount}, 'of {{pageCount}}');
    document.getElementById('pageNumber').max = pagesCount;

    PDFView.documentFingerprint = id;
    var store = PDFView.store = new ViewHistory(id);

    this.pageRotation = 0;

    var pages = this.pages = [];
    var pagesRefMap = this.pagesRefMap = {};

    var resolvePagesPromise;
    var pagesPromise = new Promise(function (resolve) {
      resolvePagesPromise = resolve;
    });
    this.pagesPromise = pagesPromise;

    var firstPagePromise = pdfDocument.getPage(1);
    var container = document.getElementById('viewer');

    // Fetch a single page so we can get a viewport that will be the default
    // viewport for all pages
    firstPagePromise.then(function(pdfPage) {
      var viewport = pdfPage.getViewport((scale || 1.0) * CSS_UNITS);

      for (var pageNum = 1; pageNum <= pagesCount; ++pageNum) {
        var viewportClone = viewport.clone();
        var pageView = new PageView(container, pageNum, scale,
                                    self.navigateTo.bind(self),
                                    viewportClone);

        pages.push(pageView);
      }

      // Fetch all the pages since the viewport is needed before printing
      // starts to create the correct size canvas. Wait until one page is
      // rendered so we don't tie up too many resources early on.
      onePageRendered.then(function () {
        if (!PDFJS.disableAutoFetch) {
          var getPagesLeft = pagesCount;
          for (var pageNum = 1; pageNum <= pagesCount; ++pageNum) {
            pdfDocument.getPage(pageNum).then(function (pageNum, pdfPage) {
              var pageView = pages[pageNum - 1];
              if (!pageView.pdfPage) {
                pageView.setPdfPage(pdfPage);
              }
              var refStr = pdfPage.ref.num + ' ' + pdfPage.ref.gen + ' R';
              pagesRefMap[refStr] = pageNum;
              getPagesLeft--;
              if (!getPagesLeft) {
                resolvePagesPromise();
              }
            }.bind(null, pageNum));
          }
        } else {
          // XXX: Printing is semi-broken with auto fetch disabled.
          resolvePagesPromise();
        }
      });

      downloadedPromise.then(function () {
        var event = document.createEvent('CustomEvent');
        event.initCustomEvent('documentload', true, true, {});
        window.dispatchEvent(event);
        self.onLoadComplete();
      });

      PDFView.loadingBar.setWidth(container);
    });

    // Fetch the necessary preference values.
    var showPreviousViewOnLoad;
    var showPreviousViewOnLoadPromise =
      Preferences.get('showPreviousViewOnLoad').then(function (prefValue) {
        showPreviousViewOnLoad = prefValue;
      });
    var defaultZoomValue;
    var defaultZoomValuePromise =
      Preferences.get('defaultZoomValue').then(function (prefValue) {
        defaultZoomValue = prefValue;
      });

    var storePromise = store.initializedPromise;
    Promise.all([firstPagePromise, storePromise, showPreviousViewOnLoadPromise,
                 defaultZoomValuePromise]).then(function resolved() {
      var storedHash = null;
      if (showPreviousViewOnLoad && store.get('exists', false)) {
        var pageNum = store.get('page', '1');
        var zoom = defaultZoomValue || store.get('zoom', PDFView.currentScale);
        var left = store.get('scrollLeft', '0');
        var top = store.get('scrollTop', '0');

        storedHash = 'page=' + pageNum + '&zoom=' + zoom + ',' +
                     left + ',' + top;
      } else if (defaultZoomValue) {
        storedHash = 'page=1&zoom=' + defaultZoomValue;
      }
      self.setInitialView(storedHash, scale);

      // Make all navigation keys work on document load,
      // unless the viewer is embedded in a web page.
      if (!self.isViewerEmbedded) {
        self.container.focus();
      }
    }, function rejected(reason) {
      console.error(reason);

      firstPagePromise.then(function () {
        self.setInitialView(null, scale);
      });
    });

    var destinationsPromise = this.destinationsPromise = pdfDocument.getDestinations();
    destinationsPromise.then(function(destinations) {
      self.destinations = destinations;
    });

    // outline depends on destinations and pagesRefMap
    var promises = [pagesPromise, destinationsPromise,
                    PDFView.animationStartedPromise];

    pdfDocument.getMetadata().then(function(data) {
      var info = data.info, metadata = data.metadata;
      self.documentInfo = info;
      self.metadata = metadata;

      // Provides some basic debug information
      /*
      console.log('PDF ' + pdfDocument.fingerprint + ' [' +
                  info.PDFFormatVersion + ' ' + (info.Producer || '-').trim() +
                  ' / ' + (info.Creator || '-').trim() + ']' +
                  ' (PDF.js: ' + (PDFJS.version || '-') +
                  (!PDFJS.disableWebGL ? ' [WebGL]' : '') + ')');
      */

      var pdfTitle;
      if (metadata && metadata.has('dc:title')) {
        var title = metadata.get('dc:title');
        // Ghostscript sometimes return 'Untitled', sets the title to 'Untitled'
        if (title !== 'Untitled') {
          pdfTitle = title;
        }
      }

      if (!pdfTitle && info && info['Title']) {
        pdfTitle = info['Title'];
      }

      if (info.IsAcroFormPresent) {
        console.warn('Warning: AcroForm/XFA is not supported');
        PDFView.fallback(PDFJS.UNSUPPORTED_FEATURES.forms);
      }
    });
  },

  setInitialView: function pdfViewSetInitialView(storedHash, scale) {
    // Reset the current scale, as otherwise the page's scale might not get
    // updated if the zoom level stayed the same.
    this.currentScale = UNKNOWN_SCALE;
    this.currentScaleValue = null;
    // When opening a new file (when one is already loaded in the viewer):
    // Reset 'currentPageNumber', since otherwise the page's scale will be wrong
    // if 'currentPageNumber' is larger than the number of pages in the file.
    document.getElementById('pageNumber').value = currentPageNumber = 1;
    // Reset the current position when loading a new file,
    // to prevent displaying the wrong position in the document.
    this.currentPosition = null;

    if (this.initialBookmark) {
      this.setHash(this.initialBookmark);
      this.initialBookmark = null;
    } else if (storedHash) {
      this.setHash(storedHash);
    } else if (scale) {
      this.setScale(scale, true);
      this.page = 1;
    }

    if (PDFView.currentScale === UNKNOWN_SCALE) {
      // Scale was not initialized: invalid bookmark or scale was not specified.
      // Setting the default one.
      this.setScale(DEFAULT_SCALE, true);
    }
  },

  renderHighestPriority:
      function pdfViewRenderHighestPriority(currentlyVisiblePages) {
    if (PDFView.idleTimeout) {
      clearTimeout(PDFView.idleTimeout);
      PDFView.idleTimeout = null;
    }

    // Pages have a higher priority than thumbnails, so check them first.
    var visiblePages = currentlyVisiblePages || this.getVisiblePages();
    var pageView = this.getHighestPriority(visiblePages, this.pages,
                                           this.pageViewScroll.down);

    // TODO: Get Page

    if (pageView) {
      this.renderView(pageView, 'page');
      return;
    }

    if (this.printing) {
      // If printing is currently ongoing do not reschedule cleanup.
      return;
    }

    PDFView.idleTimeout = setTimeout(function () {
      PDFView.cleanup();
    }, CLEANUP_TIMEOUT);
  },

  cleanup: function pdfViewCleanup() {
    for (var i = 0, ii = this.pages.length; i < ii; i++) {
      if (this.pages[i] &&
          this.pages[i].renderingState !== RenderingStates.FINISHED) {
        this.pages[i].reset();
      }
    }
    this.pdfDocument.cleanup();

  },

  getHighestPriority: function pdfViewGetHighestPriority(visible, views,
                                                         scrolledDown) {
    // The state has changed figure out which page has the highest priority to
    // render next (if any).
    // Priority:
    // 1 visible pages
    // 2 if last scrolled down page after the visible pages
    // 2 if last scrolled up page before the visible pages
    var visibleViews = visible.views;

    var numVisible = visibleViews.length;
    if (numVisible === 0) {
      return false;
    }
    for (var i = 0; i < numVisible; ++i) {
      var view = visibleViews[i].view;
      if (!this.isViewFinished(view)) {
        return view;
      }
    }

    // All the visible views have rendered, try to render next/previous pages.
    if (scrolledDown) {
      var nextPageIndex = visible.last.id;
      // ID's start at 1 so no need to add 1.
      if (views[nextPageIndex] && !this.isViewFinished(views[nextPageIndex])) {
        return views[nextPageIndex];
      }
    } else {
      var previousPageIndex = visible.first.id - 2;
      if (views[previousPageIndex] &&
          !this.isViewFinished(views[previousPageIndex])) {
        return views[previousPageIndex];
      }
    }
    // Everything that needs to be rendered has been.
    return false;
  },

  isViewFinished: function pdfViewIsViewFinished(view) {
    return view.renderingState === RenderingStates.FINISHED;
  },

  // Render a page or thumbnail view. This calls the appropriate function based
  // on the views state. If the view is already rendered it will return false.
  renderView: function pdfViewRender(view, type) {
    var state = view.renderingState;
    switch (state) {
      case RenderingStates.FINISHED:
        return false;
      case RenderingStates.PAUSED:
        PDFView.highestPriorityPage = type + view.id;
        view.resume();
        break;
      case RenderingStates.RUNNING:
        PDFView.highestPriorityPage = type + view.id;
        break;
      case RenderingStates.INITIAL:
        PDFView.highestPriorityPage = type + view.id;
        view.draw(this.renderHighestPriority.bind(this));
        break;
    }
    return true;
  },

  setHash: function pdfViewSetHash(hash) {
    var validFitZoomValues = ['Fit','FitB','FitH','FitBH',
      'FitV','FitBV','FitR'];

    if (!hash) {
      return;
    }

    if (hash.indexOf('=') >= 0) {
      var params = PDFView.parseQueryString(hash);
      // borrowing syntax from "Parameters for Opening PDF Files"
      if ('nameddest' in params) {
        PDFView.navigateTo(params.nameddest);
        return;
      }
      var pageNumber, dest;
      if ('page' in params) {
        pageNumber = (params.page | 0) || 1;
      }
      if ('zoom' in params) {
        var zoomArgs = params.zoom.split(','); // scale,left,top
        // building destination array

        // If the zoom value, it has to get divided by 100. If it is a string,
        // it should stay as it is.
        var zoomArg = zoomArgs[0];
        var zoomArgNumber = parseFloat(zoomArg);
        var destName = 'XYZ';
        if (zoomArgNumber) {
          zoomArg = zoomArgNumber / 100;
        } else if (validFitZoomValues.indexOf(zoomArg) >= 0) {
          destName = zoomArg;
        }
        dest = [null, { name: destName },
                zoomArgs.length > 1 ? (zoomArgs[1] | 0) : null,
                zoomArgs.length > 2 ? (zoomArgs[2] | 0) : null,
                zoomArg];
      }
      if (dest) {
        var currentPage = this.pages[(pageNumber || this.page) - 1];
        currentPage.scrollIntoView(dest);
      } else if (pageNumber) {
        this.page = pageNumber; // simple page
      }
    } else if (/^\d+$/.test(hash)) { // page number
      this.page = hash;
    } else { // named destination
      PDFView.navigateTo(unescape(hash));
    }
  },

  getVisiblePages: function pdfViewGetVisiblePages() {
    if (!PresentationMode.active) {
      return this.getVisibleElements(this.container, this.pages, true);
    } else {
      // The algorithm in getVisibleElements doesn't work in all browsers and
      // configurations when presentation mode is active.
      var visible = [];
      var currentPage = this.pages[this.page - 1];
      visible.push({ id: currentPage.id, view: currentPage });
      return { first: currentPage, last: currentPage, views: visible };
    }
  },

  // Generic helper to find out what elements are visible within a scroll pane.
  getVisibleElements: function pdfViewGetVisibleElements(
      scrollEl, views, sortByVisibility) {
    var top = scrollEl.scrollTop, bottom = top + scrollEl.clientHeight;
    var left = scrollEl.scrollLeft, right = left + scrollEl.clientWidth;

    var visible = [], view;
    var currentHeight, viewHeight, hiddenHeight, percentHeight;
    var currentWidth, viewWidth;
    for (var i = 0, ii = views.length; i < ii; ++i) {
      view = views[i];
      currentHeight = view.el.offsetTop + view.el.clientTop;
      viewHeight = view.el.clientHeight;
      if ((currentHeight + viewHeight) < top) {
        continue;
      }
      if (currentHeight > bottom) {
        break;
      }
      currentWidth = view.el.offsetLeft + view.el.clientLeft;
      viewWidth = view.el.clientWidth;
      if ((currentWidth + viewWidth) < left || currentWidth > right) {
        continue;
      }
      hiddenHeight = Math.max(0, top - currentHeight) +
                     Math.max(0, currentHeight + viewHeight - bottom);
      percentHeight = ((viewHeight - hiddenHeight) * 100 / viewHeight) | 0;

      visible.push({ id: view.id, x: currentWidth, y: currentHeight,
                     view: view, percent: percentHeight });
    }

    var first = visible[0];
    var last = visible[visible.length - 1];

    if (sortByVisibility) {
      visible.sort(function(a, b) {
        var pc = a.percent - b.percent;
        if (Math.abs(pc) > 0.001) {
          return -pc;
        }
        return a.id - b.id; // ensure stability
      });
    }
    return {first: first, last: last, views: visible};
  },

  // Helper function to parse query string (e.g. ?param1=value&parm2=...).
  parseQueryString: function pdfViewParseQueryString(query) {
    var parts = query.split('&');
    var params = {};
    for (var i = 0, ii = parts.length; i < ii; ++i) {
      var param = parts[i].split('=');
      var key = param[0].toLowerCase();
      var value = param.length > 1 ? param[1] : null;
      params[decodeURIComponent(key)] = decodeURIComponent(value);
    }
    return params;
  },

  beforePrint: function pdfViewSetupBeforePrint() {
    if (!this.supportsPrinting) {
      var printMessage = mozL10n.get('printing_not_supported', null,
          'Warning: Printing is not fully supported by this browser.');
      this.error(printMessage);
      return;
    }

    var alertNotReady = false;
    var i, ii;
    if (!this.pages.length) {
      alertNotReady = true;
    } else {
      for (i = 0, ii = this.pages.length; i < ii; ++i) {
        if (!this.pages[i].pdfPage) {
          alertNotReady = true;
          break;
        }
      }
    }
    if (alertNotReady) {
      var notReadyMessage = mozL10n.get('printing_not_ready', null,
          'Warning: The PDF is not fully loaded for printing.');
      window.alert(notReadyMessage);
      return;
    }

    this.printing = true;
    this.renderHighestPriority();

    var body = document.querySelector('body');
    body.setAttribute('data-mozPrintCallback', true);
    for (i = 0, ii = this.pages.length; i < ii; ++i) {
      this.pages[i].beforePrint();
    }

//#if (FIREFOX || MOZCENTRAL)
//    FirefoxCom.request('reportTelemetry', JSON.stringify({
//      type: 'print'
//    }));
//#endif
  },

  afterPrint: function pdfViewSetupAfterPrint() {
    var div = document.getElementById('printContainer');
    while (div.hasChildNodes()) {
      div.removeChild(div.lastChild);
    }

    this.printing = false;
    this.renderHighestPriority();
  },

  rotatePages: function pdfViewRotatePages(delta) {
    var currentPage = this.pages[this.page - 1];
    var i, l;
    this.pageRotation = (this.pageRotation + 360 + delta) % 360;

    for (i = 0, l = this.pages.length; i < l; i++) {
      var page = this.pages[i];
      page.update(page.scale, this.pageRotation);
    }

    this.setScale(this.currentScaleValue, true, true);

    this.renderHighestPriority();

    if (currentPage) {
      currentPage.scrollIntoView();
    }
  },

  /**
   * This function flips the page in presentation mode if the user scrolls up
   * or down with large enough motion and prevents page flipping too often.
   *
   * @this {PDFView}
   * @param {number} mouseScrollDelta The delta value from the mouse event.
   */
  mouseScroll: function pdfViewMouseScroll(mouseScrollDelta) {
    var MOUSE_SCROLL_COOLDOWN_TIME = 50;

    var currentTime = (new Date()).getTime();
    var storedTime = this.mouseScrollTimeStamp;

    // In case one page has already been flipped there is a cooldown time
    // which has to expire before next page can be scrolled on to.
    if (currentTime > storedTime &&
        currentTime - storedTime < MOUSE_SCROLL_COOLDOWN_TIME) {
      return;
    }

    // In case the user decides to scroll to the opposite direction than before
    // clear the accumulated delta.
    if ((this.mouseScrollDelta > 0 && mouseScrollDelta < 0) ||
        (this.mouseScrollDelta < 0 && mouseScrollDelta > 0)) {
      this.clearMouseScrollState();
    }

    this.mouseScrollDelta += mouseScrollDelta;

    var PAGE_FLIP_THRESHOLD = 120;
    if (Math.abs(this.mouseScrollDelta) >= PAGE_FLIP_THRESHOLD) {

      var PageFlipDirection = {
        UP: -1,
        DOWN: 1
      };

      // In presentation mode scroll one page at a time.
      var pageFlipDirection = (this.mouseScrollDelta > 0) ?
                                PageFlipDirection.UP :
                                PageFlipDirection.DOWN;
      this.clearMouseScrollState();
      var currentPage = this.page;

      // In case we are already on the first or the last page there is no need
      // to do anything.
      if ((currentPage === 1 && pageFlipDirection === PageFlipDirection.UP) ||
          (currentPage === this.pages.length &&
           pageFlipDirection === PageFlipDirection.DOWN)) {
        return;
      }

      this.page += pageFlipDirection;
      this.mouseScrollTimeStamp = currentTime;
    }
  },

  /**
   * This function clears the member attributes used with mouse scrolling in
   * presentation mode.
   *
   * @this {PDFView}
   */
  clearMouseScrollState: function pdfViewClearMouseScrollState() {
    this.mouseScrollTimeStamp = 0;
    this.mouseScrollDelta = 0;
  }
};

function webViewerLoad(pdfPath) {
  PDFView.initialize().then(function() {
    webViewerInitialized(pdfPath);
  });
}

function webViewerInitialized(file) {
  var params = PDFView.parseQueryString(document.location.search.substring(1));

  var locale = PDFJS.locale || navigator.language;

  // Special debugging flags in the hash section of the URL.
  var hash = document.location.hash.substring(1);
  var hashParams = PDFView.parseQueryString(hash);

  if ('disableworker' in hashParams) {
    PDFJS.disableWorker = (hashParams['disableworker'] === 'true');
  }
  if ('disablerange' in hashParams) {
    PDFJS.disableRange = (hashParams['disablerange'] === 'true');
  }
  if ('disablestream' in hashParams) {
    PDFJS.disableStream = (hashParams['disablestream'] === 'true');
  }
  if ('disableautofetch' in hashParams) {
    PDFJS.disableAutoFetch = (hashParams['disableautofetch'] === 'true');
  }
  if ('disablefontface' in hashParams) {
    PDFJS.disableFontFace = (hashParams['disablefontface'] === 'true');
  }
  if ('disablehistory' in hashParams) {
    PDFJS.disableHistory = (hashParams['disablehistory'] === 'true');
  }
  if ('webgl' in hashParams) {
    PDFJS.disableWebGL = (hashParams['webgl'] !== 'true');
  }
  if ('useonlycsszoom' in hashParams) {
    PDFJS.useOnlyCssZoom = (hashParams['useonlycsszoom'] === 'true');
  }
  if ('verbosity' in hashParams) {
    PDFJS.verbosity = hashParams['verbosity'] | 0;
  }
  if ('ignorecurrentpositiononzoom' in hashParams) {
    IGNORE_CURRENT_POSITION_ON_ZOOM =
      (hashParams['ignorecurrentpositiononzoom'] === 'true');
  }

  if ('disablebcmaps' in hashParams && hashParams['disablebcmaps']) {
    PDFJS.cMapUrl = '../external/cmaps/';
    PDFJS.cMapPacked = false;
  }

  if ('locale' in hashParams) {
    locale = hashParams['locale'];
  }

  if ('textlayer' in hashParams) {
    switch (hashParams['textlayer']) {
      case 'off':
        PDFJS.disableTextLayer = true;
        break;
      case 'visible':
      case 'shadow':
      case 'hover':
        var viewer = document.getElementById('viewer');
        viewer.classList.add('textLayer-' + hashParams['textlayer']);
        break;
    }
  }

  if ('pdfbug' in hashParams) {
    PDFJS.pdfBug = true;
    var pdfBug = hashParams['pdfbug'];
    var enabled = pdfBug.split(',');
    PDFBug.enable(enabled);
    PDFBug.init();
  }

  mozL10n.setLanguage(locale);

  // Listen for unsupported features to trigger the fallback UI.
  PDFJS.UnsupportedManager.listen(PDFView.fallback.bind(PDFView));

  // Suppress context menus for some controls
  document.getElementById('scaleSelect').oncontextmenu = noContextMenuHandler;

  var mainContainer = document.getElementById('mainContainer');
  var outerContainer = document.getElementById('outerContainer');
  mainContainer.addEventListener('transitionend', function(e) {
    if (e.target === mainContainer) {
      var event = document.createEvent('UIEvents');
      event.initUIEvent('resize', false, false, window, 0);
      window.dispatchEvent(event);
      outerContainer.classList.remove('sidebarMoving');
    }
  }, true);


  document.getElementById('previous').addEventListener('click',
    function() {
      var pageNum = parseInt(document.getElementById('pageNumber').value, 10);

      if (!isNaN(pageNum)) {
        PDFView.page = pageNum - 1;
      } else {
        PDFView.page--;
      }
    });

  document.getElementById('next').addEventListener('click',
    function() {
      var pageNum = parseInt(document.getElementById('pageNumber').value, 10);

      if (!isNaN(pageNum)) {
        PDFView.page = pageNum + 1;
      } else {
        PDFView.page++;
      }
    });

  document.getElementById('zoomIn').addEventListener('click',
    function() {
      PDFView.zoomIn();
    });

  document.getElementById('zoomOut').addEventListener('click',
    function() {
      PDFView.zoomOut();
    });

  document.getElementById('pageNumber').addEventListener('click',
    function() {
      this.select();
    });

  document.getElementById('pageNumber').addEventListener('change',
    function() {
      // Handle the user inputting a floating point number.
      PDFView.page = (this.value | 0);

      if (this.value !== (this.value | 0).toString()) {
        this.value = PDFView.page;
      }
    });

  document.getElementById('scaleSelect').addEventListener('change',
    function() {
      PDFView.setScale(this.value);
    });

  if (file && file.lastIndexOf('file:', 0) === 0) {
    // file:-scheme. Load the contents in the main thread because QtWebKit
    // cannot load file:-URLs in a Web Worker. file:-URLs are usually loaded
    // very quickly, so there is no need to set up progress event listeners.

    var xhr = new XMLHttpRequest();
    xhr.onload = function() {
      PDFView.open(new Uint8Array(xhr.response), 0);
    };
    try {
      xhr.open('GET', file);
      xhr.responseType = 'arraybuffer';
      xhr.send();
    } catch (e) {
      PDFView.error(mozL10n.get('loading_error', null,
            'An error occurred while loading the PDF.'), e);
    }
    return;
  }

  if (file) {
    PDFView.open(file, 0);
  }
}

//document.addEventListener('DOMContentLoaded', webViewerLoad, true);

function updateViewarea() {
  if (!PDFView.initialized) {
    return;
  }

  var visible = PDFView.getVisiblePages();
  var visiblePages = visible.views;

  if (visiblePages.length === 0) {
    return;
  }

  var suggestedCacheSize = Math.max(DEFAULT_CACHE_SIZE,
      2 * visiblePages.length + 1);
  cache.resize(suggestedCacheSize);

  PDFView.renderHighestPriority(visible);

  var currentId = PDFView.page;
  var firstPage = visible.first;

  for (var i = 0, ii = visiblePages.length, stillFullyVisible = false;
       i < ii; ++i) {
    var page = visiblePages[i];

    if (page.percent < 100) {
      break;
    }

    if (page.id === PDFView.page) {
      stillFullyVisible = true;
      break;
    }
  }

  if (!stillFullyVisible) {
    currentId = visiblePages[0].id;
  }

  var currentScale = PDFView.currentScale;
  var currentScaleValue = PDFView.currentScaleValue;
  var normalizedScaleValue = parseFloat(currentScaleValue) === currentScale ?
    Math.round(currentScale * 10000) / 100 : currentScaleValue;

  var pageNumber = firstPage.id;
  var pdfOpenParams = '#page=' + pageNumber;
  pdfOpenParams += '&zoom=' + normalizedScaleValue;
  var currentPage = PDFView.pages[pageNumber - 1];
  var container = PDFView.container;
  var topLeft = currentPage.getPagePoint((container.scrollLeft - firstPage.x),
                                         (container.scrollTop - firstPage.y));
  var intLeft = Math.round(topLeft[0]);
  var intTop = Math.round(topLeft[1]);
  pdfOpenParams += ',' + intLeft + ',' + intTop;

  document.getElementById('pageNumber').value = pageNumber;
  PDFView.currentPosition = { page: pageNumber, left: intLeft, top: intTop };

  PDFView.store.initializedPromise.then(function() {
    PDFView.store.setMultiple({
      'exists': true,
      'page': pageNumber,
      'zoom': normalizedScaleValue,
      'scrollLeft': intLeft,
      'scrollTop': intTop
    }).catch(function() {
      // unable to write to storage
    });
  });
}

window.addEventListener('resize', function webViewerResize(evt) {
  if (PDFView.initialized &&
      (document.getElementById('pageWidthOption').selected ||
       document.getElementById('pageFitOption').selected ||
       document.getElementById('pageAutoOption').selected)) {
    PDFView.setScale(document.getElementById('scaleSelect').value);
  }
  updateViewarea();
});

window.addEventListener('change', function webViewerChange(evt) {
  var files = evt.target.files;
  if (!files || files.length === 0) {
    return;
  }
  var file = files[0];

  if (!PDFJS.disableCreateObjectURL &&
      typeof URL !== 'undefined' && URL.createObjectURL) {
    PDFView.open(URL.createObjectURL(file), 0);
  } else {
    // Read the local file into a Uint8Array.
    var fileReader = new FileReader();
    fileReader.onload = function webViewerChangeFileReaderOnload(evt) {
      var buffer = evt.target.result;
      var uint8Array = new Uint8Array(buffer);
      PDFView.open(uint8Array, 0);
    };
    fileReader.readAsArrayBuffer(file);
  }
}, true);

function selectScaleOption(value) {
  var options = document.getElementById('scaleSelect').options;
  var predefinedValueFound = false;
  for (var i = 0; i < options.length; i++) {
    var option = options[i];
    if (option.value !== value) {
      option.selected = false;
      continue;
    }
    option.selected = true;
    predefinedValueFound = true;
  }
  return predefinedValueFound;
}

window.addEventListener('localized', function localized(evt) {
  document.getElementsByTagName('html')[0].dir = mozL10n.getDirection();
}, true);

window.addEventListener('scalechange', function scalechange(evt) {
  document.getElementById('zoomOut').disabled = (evt.scale === MIN_SCALE);
  document.getElementById('zoomIn').disabled = (evt.scale === MAX_SCALE);

  var customScaleOption = document.getElementById('customScaleOption');
  customScaleOption.selected = false;

  if (!evt.resetAutoSettings &&
      (document.getElementById('pageWidthOption').selected ||
       document.getElementById('pageFitOption').selected ||
       document.getElementById('pageAutoOption').selected)) {
    updateViewarea();
    return;
  }

  var predefinedValueFound = selectScaleOption('' + evt.scale);
  if (!predefinedValueFound) {
    customScaleOption.textContent = Math.round(evt.scale * 10000) / 100 + '%';
    customScaleOption.selected = true;
  }
  updateViewarea();
}, true);

window.addEventListener('pagechange', function pagechange(evt) {
  var page = evt.pageNumber;
  if (PDFView.previousPageNumber !== page) {
    document.getElementById('pageNumber').value = page;
  }
  var numPages = PDFView.pages.length;

  document.getElementById('previous').disabled = (page <= 1);
  document.getElementById('next').disabled = (page >= numPages);
}, true);

function handleMouseWheel(evt) {
  var MOUSE_WHEEL_DELTA_FACTOR = 40;
  var ticks = (evt.type === 'DOMMouseScroll') ? -evt.detail :
              evt.wheelDelta / MOUSE_WHEEL_DELTA_FACTOR;
  var direction = (ticks < 0) ? 'zoomOut' : 'zoomIn';

  if (evt.ctrlKey) { // Only zoom the pages, not the entire viewer
    evt.preventDefault();
    PDFView[direction](Math.abs(ticks));
  } else if (PresentationMode.active) {
    PDFView.mouseScroll(ticks * MOUSE_WHEEL_DELTA_FACTOR);
  }
}

window.addEventListener('DOMMouseScroll', handleMouseWheel);
window.addEventListener('mousewheel', handleMouseWheel);

window.addEventListener('keydown', function keydown(evt) {
  if (OverlayManager.active) {
    return;
  }

  var handled = false;
  var cmd = (evt.ctrlKey ? 1 : 0) |
            (evt.altKey ? 2 : 0) |
            (evt.shiftKey ? 4 : 0) |
            (evt.metaKey ? 8 : 0);

  // First, handle the key bindings that are independent whether an input
  // control is selected or not.
  if (cmd === 1 || cmd === 8 || cmd === 5 || cmd === 12) {
    // either CTRL or META key with optional SHIFT.
    switch (evt.keyCode) {
      case 70: // f
        if (!PDFView.supportsIntegratedFind) {
          PDFView.findBar.open();
          handled = true;
        }
        break;
      case 71: // g
        if (!PDFView.supportsIntegratedFind) {
          PDFView.findBar.dispatchEvent('again', cmd === 5 || cmd === 12);
          handled = true;
        }
        break;
      case 61: // FF/Mac '='
      case 107: // FF '+' and '='
      case 187: // Chrome '+'
      case 171: // FF with German keyboard
        PDFView.zoomIn();
        handled = true;
        break;
      case 173: // FF/Mac '-'
      case 109: // FF '-'
      case 189: // Chrome '-'
        PDFView.zoomOut();
        handled = true;
        break;
      case 48: // '0'
      case 96: // '0' on Numpad of Swedish keyboard
        // keeping it unhandled (to restore page zoom to 100%)
        setTimeout(function () {
          // ... and resetting the scale after browser adjusts its scale
          PDFView.setScale(DEFAULT_SCALE, true);
        });
        handled = false;
        break;
    }
  }

  if (cmd === 1 || cmd === 8) {
    switch (evt.keyCode) {
      case 83: // s
        PDFView.download();
        handled = true;
        break;
    }
  }

  // CTRL+ALT or Option+Command
  if (cmd === 3 || cmd === 10) {
    switch (evt.keyCode) {
      case 80: // p
        handled = true;
        break;
      case 71: // g
        // focuses input#pageNumber field
        document.getElementById('pageNumber').select();
        handled = true;
        break;
    }
  }

  if (handled) {
    evt.preventDefault();
    return;
  }

  // Some shortcuts should not get handled if a control/input element
  // is selected.
  var curElement = document.activeElement || document.querySelector(':focus');
  var curElementTagName = curElement && curElement.tagName.toUpperCase();
  if (curElementTagName === 'INPUT' ||
      curElementTagName === 'TEXTAREA' ||
      curElementTagName === 'SELECT') {
    // Make sure that the secondary toolbar is closed when Escape is pressed.
    if (evt.keyCode !== 27) { // 'Esc'
      return;
    }
  }

  if (cmd === 0) { // no control key pressed at all.
    switch (evt.keyCode) {
      case 38: // up arrow
      case 33: // pg up
      case 8: // backspace
        if (!PresentationMode.active &&
            PDFView.currentScaleValue !== 'page-fit') {
          break;
        }
        /* in presentation mode */
        /* falls through */
      case 37: // left arrow
        // horizontal scrolling using arrow keys
        if (PDFView.isHorizontalScrollbarEnabled) {
          break;
        }
        /* falls through */
      case 75: // 'k'
      case 80: // 'p'
        PDFView.page--;
        handled = true;
        break;
      case 27: // esc key
        if (!PDFView.supportsIntegratedFind && PDFView.findBar.opened) {
          PDFView.findBar.close();
          handled = true;
        }
        break;
      case 40: // down arrow
      case 34: // pg down
      case 32: // spacebar
        if (!PresentationMode.active &&
            PDFView.currentScaleValue !== 'page-fit') {
          break;
        }
        /* falls through */
      case 39: // right arrow
        // horizontal scrolling using arrow keys
        if (PDFView.isHorizontalScrollbarEnabled) {
          break;
        }
        /* falls through */
      case 74: // 'j'
      case 78: // 'n'
        PDFView.page++;
        handled = true;
        break;

      case 36: // home
        if (PresentationMode.active || PDFView.page > 1) {
          PDFView.page = 1;
          handled = true;
        }
        break;
      case 35: // end
        if (PresentationMode.active || (PDFView.pdfDocument &&
            PDFView.page < PDFView.pdfDocument.numPages)) {
          PDFView.page = PDFView.pdfDocument.numPages;
          handled = true;
        }
        break;

      case 72: // 'h'
        if (!PresentationMode.active) {
          HandTool.toggle();
        }
        break;
      case 82: // 'r'
        PDFView.rotatePages(90);
        break;
    }
  }

  if (cmd === 4) { // shift-key
    switch (evt.keyCode) {
      case 32: // spacebar
        if (!PresentationMode.active &&
            PDFView.currentScaleValue !== 'page-fit') {
          break;
        }
        PDFView.page--;
        handled = true;
        break;

      case 82: // 'r'
        PDFView.rotatePages(-90);
        break;
    }
  }

  if (!handled && !PresentationMode.active) {
    // 33=Page Up  34=Page Down  35=End    36=Home
    // 37=Left     38=Up         39=Right  40=Down
    if (evt.keyCode >= 33 && evt.keyCode <= 40 &&
        !PDFView.container.contains(curElement)) {
      // The page container is not focused, but a page navigation key has been
      // pressed. Change the focus to the viewer container to make sure that
      // navigation by keyboard works as expected.
      PDFView.container.focus();
    }
    // 32=Spacebar
    if (evt.keyCode === 32 && curElementTagName !== 'BUTTON') {
      if (!PDFView.container.contains(curElement)) {
        PDFView.container.focus();
      }
    }
  }

  if (cmd === 2) { // alt-key
    switch (evt.keyCode) {
      case 37: // left arrow
        if (PresentationMode.active) {
          handled = true;
        }
        break;
      case 39: // right arrow
        if (PresentationMode.active) {
          handled = true;
        }
        break;
    }
  }

  if (handled) {
    evt.preventDefault();
    PDFView.clearMouseScrollState();
  }
});

window.addEventListener('beforeprint', function beforePrint(evt) {
  PDFView.beforePrint();
});

window.addEventListener('afterprint', function afterPrint(evt) {
  PDFView.afterPrint();
});

(function animationStartedClosure() {
  // The offsetParent is not set until the pdf.js iframe or object is visible.
  // Waiting for first animation.
  PDFView.animationStartedPromise = new Promise(function (resolve) {
    window.requestAnimationFrame(resolve);
  });
})();
