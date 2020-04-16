import dom, strformat, times, jsconsole, options, pure/strutils
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

  BoardSize = object  ## Infos on size/position of a game board
    x: int            ## X position of the top left corner
    y: int            ## Y position of the top left corner
    size: int         ## Pixel size of the game board. (The board is assumed to be quadratic)
    cellSize: int     ## Pixel size of each cell in the board

const
  gameBgColor = "#eaeaea"
  okBoardColor = "#A8E5A03F"
  metaBoardColor = "#484d4d"
  miniBoardColor = "#6a6c6c"
  font = "Helvetica, monospace"
  padding = 10 # Padding around the game area in pixels

var
  debugMode = true
  # TODO this should be dynamic
  sidebarWidth = 150             ## Size of the left sidebar

proc getGameArea(game: Game): BoardSize =
  ## Get size and position of the game board on the canvas
  let height = game.renderer.getHeight - 2 * padding
  let width = game.renderer.getWidth - sidebarWidth - 3 * padding
  result.x =  2 * padding + sidebarWidth
  result.y = padding
  result.size = min(height, width)
  result.cellSize = (result.size / 3).toInt

proc getCellInfo(e: Node): tuple[cell: Coordinate, board: Coordinate] = 
  ## Parse the game imformation from the  HTML attributes of an element
  var val: string
  val = $e.getAttribute("x")
  result.cell.x = val.parseInt
  val = $e.getAttribute("y")
  result.cell.y = val.parseInt
  val = $e.getAttribute("metaX")
  result.board.x = val.parseInt
  val = $e.getAttribute("metaY")
  result.board.y = val.parseInt

proc cellClick(game: Game, event: Event): void = 
  ## TODO Process cell clicks from here
  let (cell, board) = event.target.getCellInfo()
  console.debug(fmt"Click: cell ({cell.x}, {cell.y}) in mini board ({board.x}, {board.y})")
  if game.state.currentBoard.isNone:
    discard game.state.makeMove(cell,board)
  elif board == game.state.currentBoard.get:
    discard game.state.makeMove(cell)

proc createMiniCells(game: Game, board: Coordinate, start: Point, size: float): seq[Element] =
  ## Create the interactive cells in a miniboard
  for x in 0 .. 2:
    for y in 0 .. 2:
      let pos = ((start.x + x * size).toInt, (start.y + y * size).toInt).toPoint
      let cell: Element = game.renderer.createDivElement(pos, size, size)
      cell.setAttribute("info", fmt"({x}, {y}) at {start}")
      cell.setAttribute("X", $x)
      cell.setAttribute("Y", $y)
      cell.setAttribute("metaX", $board.x)
      cell.setAttribute("metaY", $board.y)
      cell.classList.add("mttt-cell")
      cell.addEventListener("click", proc(ev: Event) = cellClick(game, ev))
      result.add cell  

proc createCellElements(game: Game): seq[Element] =
  ## Create the cell elements for the whole game board
  let area = game.getGameArea()
  for x in 0 .. 2:
    for y in 0 .. 2:
      let pos = (area.x + x * area.cellSize, area.y + y * area.cellSize)
      result.add game.createMiniCells((x, y), pos, area.cellSize / 3)

proc switchScene(game: Game, scene: Scene) =
  case scene:
    of Scene.MainMenu:
      discard
    of Scene.Game:
      let timeTextPos = (padding.toFloat, padding.toFloat).toPoint
      discard game.renderer.createTextElement("Game Time", timeTextPos, "#000000", 26, font)

      let timePos = (padding.toFloat, padding.toFloat + 35.0).toPoint
      game.timeElement = game.renderer.createTextElement("0", timePos, "#000000", 20, font)

      discard game.createCellElements()

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

proc drawBoardLines(game: Game, zero: Point, size: int, color = "#000000", pad = 10): void =
  ## Draws the lines for a tic tac toe board on the canvas
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

proc drawMark(renderer: Renderer2D, pos: Point, size: int, mark: Mark) =
  ## Draw a single mark on the canvas
  case mark:
  of Mark.Free:
    if (debugMode):
      renderer.drawImage("img/free.svg", pos, size, size, ImageAlignment.TopLeft)
  of Mark.Player1:
    renderer.drawImage("img/x.svg", pos, size, size, ImageAlignment.TopLeft)
  of Mark.Player2:
    renderer.drawImage("img/o.svg", pos, size, size, ImageAlignment.TopLeft)
  else:
    console.error(fmt"Invalid mark '{mark}'");

proc drawPlayerMarks(game: Game, zero: Point, size: int, coord: Coordinate): void = 
  ## Draw the player marks for all cells in a board
  let cellSize = (size / 3).toInt
  for x in 0 .. 2:
    for y in 0 .. 2:      
      let pos = ((zero.x + x * cellSize), (zero.y + y * cellSize)).toPoint  ## Top left point for each cell in the board
      let mark = game.state.board[coord.x][coord.y][x][y]
      game.renderer.drawMark(pos, cellSize, mark)

proc drawBoard(game: Game, zero: Point, size: int, coord: Coordinate, color = "#000000", pad = 10): void =
  ## Draw a Tic Tac Toe board with the given sizes, if the game is still open.
  ## If not, draw a big mark for the winner or something to show it is drawn
  if (debugMode): 
    game.renderer.drawPos(zero)                                   # Top left corner
    game.renderer.drawPos((zero.x + size, zero.y).toPoint)        # Top right corner
    game.renderer.drawPos((zero.x, zero.y + size).toPoint)        # Bottom left corner
    game.renderer.drawPos((zero.x + size, zero.y + size).toPoint) # Bottom right corner
  
  let status = game.state.board[coord.x][coord.y].checkBoard
  if status ==  Mark.Free:
    if (game.state.currentBoard.isNone or game.state.currentBoard.get == coord):
      game.renderer.fillRect(zero.x + 1, zero.y + 1, size - 2, size - 2, okBoardColor)
    game.drawBoardLines(zero, size, color, pad)
    game.drawPlayerMarks(zero, size, coord)
  else:
    game.renderer.drawMark(zero, size, status)

proc drawGame(game: Game) =
  ## Redraw the UI elements
  game.timeElement.innerHTML = fmt"{game.totalTime.inMinutes}m {game.totalTime.inSeconds mod 60}s"

  let area = game.getGameArea()

  # Draw a box araound the game board
  game.renderer.strokeRect(area.x, area.y, area.size, area.size, "#0000004d")
  
  # Draw the meta board
  game.drawBoardLines((area.x, area.y).toPoint, area.size, metaBoardColor, 5)

  # Draw the small boards
  for x in 0 .. 2:
    for y in 0 .. 2:
      game.drawBoard((area.x + x*area.cellSize, area.y + y*area.cellSize).toPoint, area.cellSize, (x, y), miniBoardColor, 15)

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
