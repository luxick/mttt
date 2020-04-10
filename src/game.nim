import dom, strformat, times, jsconsole

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
  gameBgColor = "#eaeaea"
  metaBoardColor = "#484d4d"
  miniBoardColor = "#6a6c6c"
  font = "Helvetica, monospace"
  padding = 10 # Padding around the game area in pixels

var
  debugMode = true
  renderWidth, renderHeight: int ## Canvas render area in pixels
  # TODO this should be dynamic
  sidebarWidth = 150             ## Size of the left sidebar

proc switchScene(game: Game, scene: Scene) =
  case scene:
    of Scene.MainMenu:
      discard
    of Scene.Game:
      let timeTextPos = (padding.toFloat, padding.toFloat).toPoint
      discard game.renderer.createTextElement("Game Time", timeTextPos, "#000000", 26, font)

      let timePos = (padding.toFloat, padding.toFloat + 35.0).toPoint
      game.timeElement = game.renderer.createTextElement("0", timePos, "#000000", 20, font)

proc newGame*(canvasId: string, debug: bool = false): Game =
  debugMode = debug
  var
    player1 = Player(name: "Player 1")
    player2 = Player(name: "Player 2")

  # Update game area size
  renderHeight = window.innerHeight
  renderWidth = window.innerWidth

  console.debug(fmt"Game area: {renderWidth}x{renderHeight}")
  
  if debugMode:
    renderHeight = renderHeight - 19  ## The size of the debug bar
    console.debug(fmt"Game area after debug check: {renderWidth}x{renderHeight}")

  result = Game(
    renderer: newRenderer2D(canvasId, renderWidth, renderHeight),
    scene: Scene.Game,
    state: newGameState(player1, player2),
    paused: false,
    startTime: getTime()
  )
  switchScene(result, Scene.Game)

proc update(game: Game, time: Duration) =
  ## Update the game logic
  # Return early if paused.
  if game.paused or game.scene != Scene.Game: return

  game.totalTime = getTime() - game.startTime

proc drawMainMenu(game: Game) =
  discard

proc drawPos(renderer: Renderer2D, x, y: float): void =    
  renderer.fillText(fmt"(x:{x.toInt}, y:{y.toInt})", (x, y).toPoint)

proc drawPos(renderer: Renderer2D, point: Point): void =
  renderer.drawPos(point.x.toFloat, point.y.toFloat)

proc drawBoard(game: Game, zero: Point, size: int, color = "#000000", pad = 10): void =
  ## Draw a Tic Tac Toe board with the given sizes
  if (debugMode): 
    game.renderer.drawPos(zero)                                   # Top left corner
    game.renderer.drawPos((zero.x + size, zero.y).toPoint)        # Top right corner
    game.renderer.drawPos((zero.x, zero.y + size).toPoint)        # Bottom left corner
    game.renderer.drawPos((zero.x + size, zero.y + size).toPoint) # Bottom right corner

  for i in 1 .. 2:
    let offX = ((size / 3) * i.toFloat) + zero.x.toFloat
    let offY = ((size / 3) * i.toFloat) + zero.y.toFloat

    game.renderer.beginPath()

    # horizontal line
    game.renderer.moveTo((zero.x+pad).toFloat, offY)
    if (debugMode): game.renderer.drawPos(zero.x.toFloat, offY)
    game.renderer.lineTo(zero.x + size - pad, offY)
    if (debugMode): game.renderer.drawPos((zero.x + size).toFloat, offY)
    # vertical line
    game.renderer.moveTo(offX, (zero.y+pad).toFloat)
    if (debugMode): game.renderer.drawPos(offX, zero.y.toFloat)
    game.renderer.lineTo(offX, zero.y + size - pad)
    if (debugMode): game.renderer.drawPos(offX, (zero.y + size).toFloat)

    game.renderer.closePath()
    game.renderer.strokePath(color, 3)

proc drawGame(game: Game) =
  ## Redraw the UI elements
  game.timeElement.innerHTML = fmt"{game.totalTime.inMinutes}m {game.totalTime.inSeconds mod 60}s"

  let
    gAreaX = 2 * padding + sidebarWidth
    gAreay = padding
    gAreaH = renderHeight - 2 * padding
    gAreaW = renderWidth - sidebarWidth - 3 * padding
    gSize = min(gAreaH, gAreaW)
    bSize = (gSize / 3).toInt

  # Draw a box araound the game board
  game.renderer.strokeRect(gAreaX, gAreaY, gSize, gSize, "#0000004d")
  
  # Draw the meta board
  game.drawBoard((gAreaX, gAreaY).toPoint, gSize, metaBoardColor, 5)

  # Draw the small boards
  for x in 0 .. 2:
    for y in 0 .. 2:
      game.drawBoard((gAreaX + x*bSize, gAreaY + y*bSize).toPoint, bSize, miniBoardColor, 15)

proc draw(game: Game) =
  ## Draw the current screen on the canvas

  # Fill background color.
  game.renderer.fillRect(0.0, 0.0, renderWidth, renderHeight, gameBgColor)

  case game.scene
  of Scene.MainMenu:
    drawMainMenu(game)
  of Scene.Game:
    drawGame(game)

proc nextFrame*(game: Game, frameTime: Duration) =
  ## Prepare the next frame that should be displayed
  # Determine if an update is necessary
  game.update(frameTime)
  game.draw()
