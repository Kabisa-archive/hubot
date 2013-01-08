# Description:
#   Matches all known branches in a Github repo against a regular expression.
#   Lists all matches.
#
# Dependencies:
#   "githubot": "0.2.0"
#
# Configuration:
#   HUBOT_GITHUB_REPOS
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
  robot.respond /(?:list|find|search|grep) (?:features?|branche?s?) (.+)/i, (msg) ->
    regex = new RegExp msg.match[1], 'i'

    repo_reporter = (repo) ->
      (repo_branches) ->
        branches = (branch.name for branch in repo_branches when regex.test branch.name)
        if branches.length is 0
          msg.reply "No matching branches found in #{repo}"
        else if branches.length is 1
          msg.reply "Found in #{repo}: " + branches[0]
        else
          msg.reply "Found #{branches.length} in #{repo}:\n" + branches.join("\n")

    for repo in process.env.HUBOT_GITHUB_REPOS.split ','
      github.get "https://api.github.com/repos/#{github.qualified_repo repo}/branches", repo_reporter(repo)
