# Description:
#   Push it! Push it real good!
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   (push it|pushed it) - Push it real good!
#
# Author:
#   ariejan

module.exports = (robot) ->
  robot.hear /push(|es|ed) it/i, (msg) ->
    msg.send "/play pushit"
