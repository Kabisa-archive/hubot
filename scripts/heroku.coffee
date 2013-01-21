# Description:
#   Runs a series of predefined tasks for given Heroku applications.
#
# Dependencies:
#   "heroku-api": "*"
#
# Configuration:
#   HUBOT_HEROKU_API_TOKEN
#   HUBOT_HEROKU_DEFAULT_WORKER_TYPE
#   HUBOT_HEROKU_DEFAULT_WORKER_QUANTITY_ON
#   HUBOT_HEROKU_DEFAULT_WORKER_QUANTITY_OFF
#
# Commands:
#   hubot help heroku - explain how to work with Heroku
#   hubot backup foo - return link to dump of latest backup of app foo
#   hubot hire workers for foo - add a pre-set number of workers to app foo
#   hubot fire workers for foo - reduce workers to a pre-set level for app foo
#   hubot show workers for foo - list running processes for app foo
#   hubot show releases of foo - show release information for app foo
#
# Notes:
#   None
#
# Author:
#   Arjan van der Gaag
module.exports = (robot) ->
  Heroku = require 'heroku-api'

  class HerokuRepo
    constructor: (@api_token) ->
      @repo = []

    get: (app_name) ->
      unless @repo.hasOwnProperty app_name
        @repo[app_name] = new Heroku
          app: app_name
          api_token: @api_token
      @repo[app_name]

  repo                        = new HerokuRepo process.env.HUBOT_HEROKU_API_TOKEN
  default_worker_type         = process.env.HUBOT_HEROKU_DEFAULT_WORKER_TYPE
  default_worker_quantity_on  = process.env.HUBOT_HEROKU_DEFAULT_WORKER_QUANTITY_ON
  default_worker_quantity_off = process.env.HUBOT_HEROKU_DEFAULT_WORKER_QUANTITY_OFF

  robot.respond /help heroku/i, (msg) ->
    msg.reply """
Available commands:
* backup my_app
* show workers for my_app
* show releases for my_app
* hire workers for my_app
* fire workers for my_app
"""

  robot.respond /backup ([\w\-]+)/i, (msg) ->
    app = repo.get msg.match[1]
    app.latestBackup (err, backup) ->
      if err
        msg.reply err.error
      else
        msg.reply "Here's an auto-expiring link to the latest backup #{msg.match[1]}: #{backup.public_url}"

  robot.respond /hire workers for ([\w\-]+)/i, (msg) ->
    app = repo.get msg.match[1]
    app.scale default_worker_type, default_worker_quantity_on, ->
      msg.reply "I've hired #{default_worker_quantity_on} unskilled workers on temporary contracts."

  robot.respond /fire workers for ([\w\-]+)/i, (msg) ->
    app = repo.get msg.match[1]
    app.scale default_worker_type, default_worker_quantity_off, ->
      msg.reply "I've fired all temporary workers."

  robot.respond /show releases (?:of|for) ([\w\-]+)/i, (msg) ->
    app = repo.get msg.match[1]
    app.releases (err, releases) ->
      if err
        msg.reply err.error
      else
        msg.reply "I've found these releases"
        msg.send ("#{r.name}: #{r.descr} (#{r.created_at})\n" for r in releases).slice(0,20).join()

  robot.respond /show workers for ([\w\-]+)/i, (msg) ->
    app = repo.get msg.match[1]
    app.ps (err, processes) ->
      if err
        msg.reply err.error
      else
        msg.reply "I've found these processes:"
        msg.send ("#{p.process}: #{p.state}\n" for p in processes).join()
