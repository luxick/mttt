import dom, jsconsole, sugar

import src/game

const
  canvasId = "game_canvas"

proc onTick(game: Game, time: float) =
  discard window.requestAnimationFrame((time: float) => onTick(game, time))
  game.nextFrame(time)

proc onLoad(event: Event) {.exportc.} =
  var game = newGame(canvasId, window.innerWidth, window.innerHeight)
  onTick(game, 60)

window.onload = onLoad