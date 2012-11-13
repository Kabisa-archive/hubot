# Huboku -- control Heroku with Hubot
#
# This should provide basic Heroku API operations controlled by Hubot. Note
# that it should not actually change much, just tell you stuff about apps, for
# obvious security reasons.
#
# Proposed hubot API:
#
#   hubot hire workers for [app] - scale predefined processes up to predefined quantity
#   hubot fire workers for [app] - scale predefined processes down to predefined quantity
#   hubot show me the payroll for [app] - show PS output
#   hubot list releases for [app] - show app releases
#   hubot dump [app] - get S3 URL to latest backup
#   hubot backup [app] - create a new backup for an app
#
# TODO
#
# * Provide decent error handling for failed responses
# * Provide decent error handling for invalid credentials
# * Separate Heroku client into own module
# * Create Hubot script that reads credentials from env vars
# * Create Hubot message parsers to respond to API
# * Make sure Hubot cannot do anything harmful
#
http        = require 'https'
url         = require 'url'
querystring = require 'querystring'

# Merge two objects, and merge values if values are objects themselves.
deepExtend = (a, b) ->
  for key, value of b
    if value is Object value
      a[key] ?= {}
      a[key] = deepExtend a[key], value
    else
      a[key] = value
  a

# Create a new base64-encoded buffer string from given arguments, used for HTTP
# basic auth.
authBuffer = ->
  args = Array.prototype.slice.call arguments
  return new Buffer(args.join ':').toString 'base64'

# Incoming stream from API calls. Collect chunks of data and, when done, return
# it after parsing it as JSON.
class ResponseStream
  constructor: (@data = '') ->

  push: (data) =>
    @data += data

  toJSON: =>
    JSON.parse @data

# Custom options object that handles post data, defaults and generating proper
# HTTP authorization.
class RequestOptions
  constructor: (username, password, @options) ->
    defaults =
      username: username
      password: password
      host:     'api.heroku.com'
      method:   'GET'
      headers:
        'Accept': 'application/json'
        'X-Heroku-Gem-Version': '2.1.2'

    @options = deepExtend defaults, @options

    auth = authBuffer @options.username, @options.password
    @options.headers['Authorization'] ||= "Basic #{auth}"

    @post_data = querystring.stringify @options.post_data
    delete @options.post_date
    delete @options.username
    delete @options.password

# Heroku object is a wrapper around an app, authenticated with an API key. You
# can perform operations against that app.
class Heroku
  constructor: (options) ->
    @app      = options.app
    @username = ''
    @password = options.api_key

  # Do a request to the Heroku API. You probably don't need to use it,
  # as the other functions wrap this function.
  #
  request: (options, fn) ->
    ro = new RequestOptions @username, @password, options
    req = http.request ro.options, (response) =>
      r = new ResponseStream
      response.setEncoding 'utf-8'
      response.on 'data', r.push
      response.on 'end', ->
        fn r.toJSON()
      response.on 'error', ->
        throw arguments.toString()
    req.write ro.post_data if ro.post_data
    req.end()

  # Request a configuration variable. Results are cached, but you still need
  # to provide a callback function to handle the result.
  #
  # Example:
  #
  #   heroku.config 'RACK_ENV', (rack_env) ->
  #     console.log rack_env # "production"
  config: (key, fn) ->
    return fn.call @, @cache_config[key] if @cache_config?
    path = "/apps/#{@app}/config_vars"
    @request path: path, (@cache_config) =>
      fn.call this, @cache_config[key]

  # Get details of the latest backup created with the pgbackups add-on. Use this
  # to get a S3 URL to the dump file.
  #
  # Example:
  #
  #   heroku.latestBackup (backup) ->
  #     console.log backup.public_url # "http://..."
  latestBackup: (fn) ->
    @config 'PGBACKUPS_URL', (u) ->
      throw 'No pgbackups add-on available' unless u
      u = url.parse u
      @request
        path: '/client/latest_backup'
        host: u.host
        headers:
          'Authorization': "Basic #{@authBuffer u.auth}"
      , fn

  # List releases for the current application.
  #
  # Example:
  #
  #   heroku.releases (releases) ->
  #     console.log release for release in releases
  releases: (fn) ->
    @request path: "/apps/#{@app}/releases", fn

  # List running processes for the current application
  #
  # Example:
  #
  #   heroku.ps (ps) ->
  #     console.log process for process in ps
  ps: (fn) ->
    @request path: "/apps/#{@app}/ps", fn

  # Scale a process type to a new quantity for this application.
  #
  # Example:
  #
  #   heroku.scale 'worker', 3
  scale: (type, qty) ->
    @request
      path: "/apps/#{@app}/ps/scale"
      post_data:
        type: type
        qty: qty
      method: 'POST'
    , console.log
