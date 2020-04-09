import dom, jsconsole, sugar, times, strformat

import src/game

const
  canvasId = "game_canvas"

var frameCount = 0
var mtttGame: Game
var startTime, now, then: Time
var elapsed, fpsInterval: Duration

proc animate(): void =
  # request another frame
  discard window.requestAnimationFrame((time: float) => animate())
  # calc elapsed time since last loop
  now = getTime();
  elapsed = now - then;

  # if enough time has elapsed, draw the next frame
  if elapsed > fpsInterval:
      # Get ready for next frame by setting then=now, but also adjust for your
      # specified fpsInterval not being a multiple of RAF's interval (16.7ms)
      then = now - fpsInterval
      var sinceStart = now - startTime;
      frameCount.inc
      var currentFps = (1000 / (sinceStart.inMilliseconds.int / frameCount) * 100) / 100;

      var e: Element
      e = dom.document.getElementById("fps")
      e.innerHTML = fmt"Current FPS: {currentFps:9.2f}"
      e = dom.document.getElementById("fps-interval")
      e.innerHTML = fmt"FPS Interval: {fpsInterval}"
      e = dom.document.getElementById("then")
      e.innerHTML = fmt"Seconds since start: {sinceStart.inSeconds}"

      mtttGame.nextFrame(elapsed)

proc startAnimating(fps: int): void =
  fpsInterval = initDuration(milliseconds = (1000 / fps).toInt)
  then = getTime()
  startTime = then
  animate()

proc onLoad(event: Event) {.exportc.} =
  mtttGame = newGame(canvasId, window.innerWidth, window.innerHeight)
  startAnimating(60)

window.onload = onLoad