## Prerequisites

You will need the following things properly installed on your computer.

* [Git](http://git-scm.com/)
* [Ruby](https://www.ruby-lang.org/en/)

## Installation

* `git clone <repository-url>` this repository
* change into the new directory
* `gem install bundler`
* `bundle install`
* `cp .env.example .env`
* edit the environment variables in `.env`

## Running / Development

* `middleman`
* Visit your app at [http://localhost:4567](http://localhost:4567).

## Contentful API Keys

To access Contentful you need at least an access token. This access token can be found after you logged in into [Contentful](https://app.contentful.com/), have permission to access the `Tech blog` space and navigate to [APIs](https://app.contentful.com/spaces/8v4g74v8oew0/api/keys/).

To get more information how to get authorization for the proper space, please send a request to ms@kabisa.nl.

### Fetch updated entries from Contentful
* `middleman contentful`
