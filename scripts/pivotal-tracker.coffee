# Description:
#   Describes a user story from Pivotal Tracker for you.
#
#     hubot describe story 31445781
#     feature 31445781 As a user I want to log in (2)
#     http://www.pivotaltracker.com/123456/31445781
#
# Dependencies:
#   "pivotal": "0.1.3"
#
# Configuration:
#   PIVOTAL_TRACKER_TOKEN
#   PIVOTAL_TRACKER_PROJECT_ID
#
# Commands:
#   describe story n - fetch and show information about story n
#
# Author:
#   avdgaag

module.exports = (robot) ->
  pt = require 'pivotal'
  pt.useToken process.env.PIVOTAL_TRACKER_TOKEN
  project_id = process.env.PIVOTAL_TRACKER_PROJECT_ID

  # Match either a URL or a 8-digit number. When there is a URL, capture group 1 will be empty
  # and thus fail the isNaN test. In other words: a poor man's negative look-behind.
  robot.respond /describe story (\d+)/, (msg) ->
    story_number = msg.match[1]
    return if isNaN story_number

    pt.getStory project_id, story_number, (error, story) ->
      if error
        console.log error
        return
      msg.reply "#{story.story_type} #{story_number} (#{story.estimate}): #{story.name}\n#{story.url}"
