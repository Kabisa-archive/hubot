# Description:
#   Matches all known branches in a Github repo against a regular expression.
#   Lists all matches.
#
# Dependencies:
#   "githubot": "0.2.0"
#
# Configuration:
#   HUBOT_GITHUB_REPO
#   HUBOT_GITHUB_TOKEN
#
# Commands:
#   hubot find branch foobar - show branches contain "foobar"
#
# Notes:
#   None
#
# Author:
#   Arjan van der Gaag
module.exports = (robot) ->
  github = require('githubot')(robot)
  robot.respond /(?:find|search|grep) branch(?:es)? (.+)/i, (msg) ->
    regex = new RegExp msg.match[1], 'i'
    bot_github_repo = github.qualified_repo process.env.HUBOT_GITHUB_REPO
    github.get "https://api.github.com/repos/#{bot_github_repo}/branches", (branches) ->
      branches = (branch.name for branch in branches when regex.test branch.name)
      if branches.length is 0
        msg.reply "Sorry dude, nothing found."
      else if branches.length is 1
        msg.reply "This is it: " + branches[0]
      else
        msg.reply "I found these branches:\n" + branches.join("\n")
