import dom, strformat, times, jsconsole
import gamelight/[graphics, vec]
import libmttt

from lenientops import `*`, `+`
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
  # TODO this should be dynamic
  sidebarWidth = 150             ## Size of the left sidebar

proc cellClick(event: Event): void = 
  ## TODO Process cell clicks from here
  let 
    cX = event.target.getAttribute("x")
    cY = event.target.getAttribute("y")
    mX = event.target.getAttribute("metaX")
    mY = event.target.getAttribute("metaY")
  console.debug(fmt"Click: cell ({cX}, {cY}) in mini board ({mX}, {mY})")

proc createMiniCells(renderer: Renderer2D, board: Coordinate, start: Point, size: float): seq[Element] =
  ## Create the interactive cells in a miniboard
  for x in 0 .. 2:
    for y in 0 .. 2:
      let pos = (start.x + x * size, start.y + y * size).toPoint
      let cell: Element = renderer.createDivElement(pos, size, size)
      cell.setAttribute("info", fmt"({x}, {y}) at {start}")
      cell.setAttribute("X", $x)
      cell.setAttribute("Y", $y)
      cell.setAttribute("metaX", $board.x)
      cell.setAttribute("metaY", $board.y)
      cell.onclick = cellClick
      cell.classList.add("mttt-cell")
      result.add cell

proc createCellElements(renderer: Renderer2D): seq[Element] =
  ## Create the cell elements for the whole game board
  # TODO: put those somewhere shared
  let
    gAreaX = 2 * padding + sidebarWidth
    gAreaY = padding
    gAreaH = renderer.getHeight - 2 * padding
    gAreaW = renderer.getWidth - sidebarWidth - 3 * padding
    gSize = min(gAreaH, gAreaW)
    bSize = (gSize / 3)
  
  for x in 0 .. 2:
    for y in 0 .. 2:
      let pos = (gAreaX + x * bSize, gAreaY + y * bSize)
      result.add renderer.createMiniCells((x, y), pos, bSize / 3)

proc switchScene(game: Game, scene: Scene) =
  case scene:
    of Scene.MainMenu:
      discard
    of Scene.Game:
      let timeTextPos = (padding.toFloat, padding.toFloat).toPoint
      discard game.renderer.createTextElement("Game Time", timeTextPos, "#000000", 26, font)

      let timePos = (padding.toFloat, padding.toFloat + 35.0).toPoint
      game.timeElement = game.renderer.createTextElement("0", timePos, "#000000", 20, font)

      # TODO Save these somewhere???
      let elements = game.renderer.createCellElements()

proc newGame*(canvasId: string, debug: bool = false): Game =
  debugMode = debug
  var
    player1 = Player(name: "Player 1")
    player2 = Player(name: "Player 2")

  result = Game(
    renderer: newRenderer2D(canvasId, window.innerWidth, window.innerHeight),
    scene: Scene.Game,
    state: newGameState(player1, player2),
    paused: false,
    startTime: getTime()
  )
  result.renderer.setScaleToScreen(true)
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
    gAreaH = game.renderer.getHeight - 2 * padding
    gAreaW = game.renderer.getWidth - sidebarWidth - 3 * padding
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
  game.renderer.fillRect(0.0, 0.0, game.renderer.getWidth, game.renderer.getHeight, gameBgColor)

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
