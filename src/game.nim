import dom, math, strformat, times

import gamelight/[graphics, vec]

import libmttt

type
  Game* = ref object
    renderer: Renderer2D
    startTime: Time
    totalTime*: Duration
    paused: bool
    scene: Scene
    state: GameState
    timeElement: Element
    onGameStart*: proc (game: Game)

  Scene {.pure.} = enum
    MainMenu, Game

const
  gameBgColor = "#e6e6e6"
  font = "Helvetica, monospace"
  padding = 10 # Padding around the game area in pixels

var
  renderWidth, renderHeight: int ## Canvas render area in pixels

proc toTimeString(milliseconds: float): string =
  let seconds = ((milliseconds / 1000) mod 60).toInt()
  let minutes = ((milliseconds / (1000 * 60)) mod 60).toInt()
  let hours = ((milliseconds / (1000 * 60 * 60)) mod 24).toInt()
  result = fmt"{hours}:{minutes}:{seconds}"

proc switchScene(game: Game, scene: Scene) =
  case scene:
    of Scene.MainMenu:
      discard
    of Scene.Game:
      var elements: seq[Element] = @[]

      let timeTextPos = (padding.toFloat, padding.toFloat).toPoint
      elements.add game.renderer.createTextElement("Time", timeTextPos, "#000000", 26, font)

      let timePos = (padding.toFloat, padding.toFloat + 35.0).toPoint
      game.timeElement = game.renderer.createTextElement("0", timePos, "#000000", 14, font)


proc newGame*(canvasId: string, width, height: int): Game =
  var
    player1 = Player(name: "Player 1")
    player2 = Player(name: "Player 2")

  renderWidth = width
  renderHeight = height

  result = Game(
    renderer: newRenderer2D(canvasId, width, height),
    scene: Scene.Game,
    state: newGameState(player1, player2),
    paused: false,
    startTime: getTime()
  )
  switchScene(result, Scene.Game)

proc update(game: Game, time: Duration) =
  # Update the game logic
  # Return early if paused.
  if game.paused or game.scene != Scene.Game: return

  game.totalTime = getTime() - game.startTime

proc drawMainMenu(game: Game) =
  discard

proc drawGame(game: Game) =
  # Draw changing UI Elements
  game.timeElement.innerHTML = fmt"{game.totalTime.inMinutes}m {game.totalTime.inSeconds mod 60}s"

proc draw(game: Game) =
  # Draw the current screen on the canvas
  # Fill background color.
  game.renderer.fillRect(0.0, 0.0, renderWidth, renderHeight, gameBgColor)
  case game.scene
  of Scene.MainMenu:
    drawMainMenu(game)
  of Scene.Game:
    drawGame(game)

proc nextFrame*(game: Game, frameTime: Duration) =
  # Determine id an update is necessary
  game.update(frameTime)
  game.draw()
