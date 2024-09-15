[![Gem Version](https://badge.fury.io/rb/cookies_eu.svg)](https://badge.fury.io/rb/cookies_eu)

# CookiesEu

Gem to add cookie consent to rails application

## Supported languages

* Albanian
* Basque
* Bulgarian
* Catalan
* Croatian
* Czech
* Danish
* Dutch
* English
* Estonian
* Finnish
* French
* German
* Greek
* Hebrew
* Hungarian
* Italian
* Lithuanian
* Norwegian
* Polish
* Portuguese
* Romanian
* Russian
* Slovenian
* Spanish
* Swedish
* Turkish
* Ukrainian

## Screenshot

![Cookies eu screenshot](https://user-images.githubusercontent.com/2737390/86209657-5a5e8b00-bb73-11ea-91fc-e5ff36af148f.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cookies_eu'
```

And then execute:

    $ bundle

Run the installation generator:

    $ bundle exec rails g cookies_eu:install

Or manually add in application.js:

    //= require cookies_eu

And in application.css:

    *= require cookies_eu

Or, if you have application.scss:

    @import "cookies_eu";

Remember to restart your server!

## Usage

In your view add

```ruby
= render 'cookies_eu/consent_banner'
```

You can add a link parameter to link to your cookies explanation page (you have to create the page and controller for this)

```ruby
= render 'cookies_eu/consent_banner', link: '/cookies'
```

You can add a target parameter to the link to open in a new tab

```ruby
= render 'cookies_eu/consent_banner', link: '/cookies', target: '_blank'
```

If you wish to customize the style of the div the classes are:

```css
.cookies-eu                 /* main div */
.cookies-eu-content-holder  /* content holder */
.cookies-eu-button-holder   /* button holder */
.cookies-eu-ok              /* button */
.cookies-eu-link            /* link */
```

If you wish to customize the HTML, create a folder `cookies_eu`, create a partial `_consent_banner.html.erb` and paste the HTML from [here](app/views/cookies_eu/_consent_banner.html.erb)

If you wish to run some arbitrary code when the user acknowledges the cookie message, you can register a callback. This is useful if you wish to persist the user's preference to the database.

```javascript
document.addEventListener('cookies-eu-acknowledged', function() {
  // The user has acknowledged cookies! If they're logged in, make an api call
  // so we remember their preference.
  fetch('...');
});
```

## Cookies used

This gem uses a cookie called **cookie_eu_consented** to track whether a user has accepted the cookie notice and whether it needs to be shown again or not.

## Turbolinks 5+

Is supported out of the box, just require it before cookies_eu

    //= require turbolinks
    //= require cookies_eu

## Sample of cookie info (in [haml form](/app/views/cookies_eu/cookies_info.html.haml))

### COOKIES

Cookies are small text files which are downloaded to your computer, tablet or mobile phone when you visit a website or application. The website or application may retrieve these cookies from your web browser (eg Internet Explorer, Mozilla Firefox or Google Chrome) each time you visit, so they can recognise you, remember your preferences and provide you with a more secure online experience.

Generally, cookies are very useful and are a common method used by almost every website you visit because they help to make your online experience as smooth as possible. For security reasons, many websites will not function at all without the use of cookies (or other similar technologies, such as "web beacons" or "tags").

Cookies generally do not hold any information to identify an individual person, but are instead used to identify a browser on an individual machine.

If you prefer, you can restrict, block or delete cookies by changing your browser settings but that may mean that the website won't work properly

For more information about cookies and their impact on you and your browsing visit www.aboutcookies.org.

### TYPES OF COOKIES

#### Necessary cookies

These cookies are essential in helping you to make use of the features and services we offer on the #{INSERT SITE HERE} website. Without these cookies, the services you want to use cannot be provided. These cookies do not gather information about you that could be used to identify you, and they do not monitor or remember where you have been on the internet.

#### Functional cookies

These cookies allow us to provide you with a better online experience when you use our website. They do not gather or store any information which would allow us to identify you personally.

#### Performance cookies

Performance cookies help us to understand how our customers use our site, so we can keep our products and services relevant, easy to use and up to date. For example, we can see which products and services are most popular, identify when and where errors occur, and test different versions of a page in order to provide an improved online experience.

Sometimes, the services we use to collect this information may be operated by other companies on our behalf. They may use similar technologies to cookies, known as "web beacons" or "tags". These are anonymous and, as they are only used for statistical purposes, they do not contain or collect any information that identifies you.

#### Targeting cookies

We have relationships with carefully selected and monitored suppliers (third parties) who may also set cookies during your visit. The purpose of these cookies is "behavioural advertising" (also known as "behavioural targeting" or "remarketing"), which is a means of showing you relevant products and services based on what you appear to be interested in. Although these cookies can track your visits around the web they don't know who you are. Without these cookies, online advertisements you encounter will be less relevant to you and your interests.

### MANAGING COOKIES

Most internet browsers allow you to erase cookies from your computer hard drive, block all cookies (or just third-party cookies) or warn you before a cookie is stored on your device.

Please note, if you choose to block all cookies, our site will not function as intended and you will not be able to use or access many of the services we provide. If you have blocked all cookies and wish to make full use of the features and services we offer, you will need to enable your cookies. You can do this in your browser (see below).

Rather than blocking all cookies, you can choose to only block third-party cookies which will still allow our website to function as intended.

#### How to manage cookies on your PC

To enable cookies on our website, follow the steps below.

##### Google Chrome

1. Click "Tools" at the top of your browser and select "Settings".
2. Click "Show advanced settings", scroll down to the section "Privacy" and click "Content Settings."
3. Select "Allow local data to be set". To only accept first-party cookies, check the box next to "Block all third-party cookies without exception"

##### Microsoft Internet Explorer 6.0, 7.0, 8.0, 9.0

1. Click "Tools" at the top of your browser and select "Internet Options", then click the "Privacy" tab.
2. Check that the level of your privacy is set to Medium or lower, which will allow the use of cookies in your browser.
3. If set above medium level it will prevent the use of cookies.

##### Mozilla Firefox

1. Click "Tools" at the top of your browser and select "Options".
2. Then select the "Privacy" icon.
3. Click the "Cookies" and select "Allow pages to create a cookie."

##### Safari

1. Click the gear icon at the top of your browser and select "Settings".
2. Click the "Privacy" tab, then select the option "Disable the use of cookies by third parties and advertising cookies."
3. Click "Save".

#### How to manage cookies on your Mac

To enable cookies on our website, follow the steps below.

##### Microsoft Internet Explorer 5.0 on OSX

1. Click on "Explorer" at the top of your browser and select "Settings".
2. Scroll down to the "Cookies" section in the "Received Files".
3. Select "Do not ask."

##### Safari on OSX

1 Click "Safari" on the top of your browser and select "Settings".
2 Click the "Privacy" and then "Enable cookies."
3 Select "only the pages you have visited."

##### Mozilla and Netscape on OSX

1 Click "Mozilla" or "Netscape" at the top of your browser and select "Settings".
2 Scroll down to the "Cookies" under "Privacy & Security".
3 Select "Allow cookies only to the original site."

##### Opera

1 Click "Menu" on the top of your browser and select "Settings".
2 Then select "Options" tab and the "Advanced".
3 Select "Enable cookies."

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

Maintained and sponsored by
[Infinum](http://www.infinum.co).

<img src="https://infinum.co/infinum.png" width="264">
