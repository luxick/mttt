# Package

version       = "0.1.0"
author        = "luxick"
description   = "Meta Tic Tac Toe"
license       = "GPL-2.0"
srcDir        = "src"
bin           = @["mttt"]

backend       = "js"

# Dependencies

requires "nim >= 1.0.0"

task debug, "Compile debug client":
  exec "nim js --out:public/mttt.js -d:local mttt.nim"

task release, "Compile release client":
  exec "nim js --out:public/mttt.js mttt.nim"