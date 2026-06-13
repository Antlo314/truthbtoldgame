extends "res://scripts/ui/mg_base.gd"
## The Stacker — a falling-block line-clear game. Clear the target number of
## rows to open the seal. "He set the foundations of the deep in their order."
## Touch buttons + keyboard (A/D move, W rotate, S soft-drop, Space hard-drop).

const COLS := 8
const ROWS := 14
const CELL := 26
const TARGET_LINES := 2
const TICK := 0.6  # seconds per gravity step

const SHAPES := [
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],   # I
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],    # O
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],   # T
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)],   # S
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],   # Z
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],   # J
	[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 1)],  # L
]
const PIECE_COLORS := [
	Color(0.45, 0.80, 0.92), Color(0.95, 0.82, 0.40), Color(0.72, 0.50, 0.90),
	Color(0.55, 0.85, 0.45), Color(0.90, 0.45, 0.45), Color(0.45, 0.55, 0.90),
	Color(0.95, 0.65, 0.40),
]

var _grid: Array = []          # ROWS x COLS, -1 empty else color index
var _cells: Array = []         # active piece cell offsets (Vector2i)
var _color := 0
var _pivot := Vector2i.ZERO
var _lines := 0
var _accum := 0.0
var _board: BoardDraw


class BoardDraw extends Control:
	var owner_mg
	func _draw() -> void:
		var w: int = owner_mg.COLS * owner_mg.CELL
		var h: int = owner_mg.ROWS * owner_mg.CELL
		var origin := (size - Vector2(w, h)) * 0.5
		draw_rect(Rect2(origin - Vector2(4, 4), Vector2(w + 8, h + 8)), Color(0.10, 0.11, 0.16))
		# grid + locked cells
		for r in mg().ROWS:
			for c in mg().COLS:
				var cell := Rect2(origin + Vector2(c, r) * mg().CELL + Vector2(1, 1), Vector2(mg().CELL - 2, mg().CELL - 2))
				var v: int = owner_mg._grid[r][c]
				if v >= 0:
					draw_rect(cell, mg().PIECE_COLORS[v])
				else:
					draw_rect(cell, Color(0.16, 0.17, 0.22))
		# active piece
		for off in owner_mg._cells:
			var p: Vector2i = owner_mg._pivot + off
			if p.y < 0:
				continue
			var cell := Rect2(origin + Vector2(p.x, p.y) * mg().CELL + Vector2(1, 1), Vector2(mg().CELL - 2, mg().CELL - 2))
			draw_rect(cell, mg().PIECE_COLORS[owner_mg._color])

	func mg():
		return owner_mg


func build() -> void:
	for r in ROWS:
		var row := []
		for c in COLS:
			row.append(-1)
		_grid.append(row)

	_board = BoardDraw.new()
	_board.owner_mg = self
	_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board.offset_bottom = -64.0
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_board)

	_controls()
	_spawn()
	set_instruction("Clear %d rows. Fill a row across to clear it." % TARGET_LINES)


func _controls() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -250.0
	bar.offset_right = 250.0
	bar.offset_top = -58.0
	bar.offset_bottom = -6.0
	content.add_child(bar)
	for spec in [["◄", Callable(self, "_move").bind(-1)], ["⟳", Callable(self, "_rotate")],
			["►", Callable(self, "_move").bind(1)], ["▼", Callable(self, "_hard_drop")]]:
		var b := Button.new()
		b.text = spec[0]
		b.add_theme_font_size_override("font_size", 26)
		b.custom_minimum_size = Vector2(112, 50)
		b.pressed.connect(spec[1])
		bar.add_child(b)


func _spawn() -> void:
	var t := randi() % SHAPES.size()
	_color = t
	_cells = SHAPES[t].duplicate()
	_pivot = Vector2i(COLS / 2 - 1, 0)
	if not _fits(_cells, _pivot):
		# Board choked — soften it: clear the bottom rows and continue.
		for r in range(ROWS - 4, ROWS):
			for c in COLS:
				_grid[r][c] = -1
		set_instruction("The stack buckled — keep going.")
	_board.queue_redraw()


func _process(delta: float) -> void:
	if _board == null:
		return
	_accum += delta
	if _accum >= TICK:
		_accum = 0.0
		_step_down()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_A, KEY_LEFT: _move(-1)
			KEY_D, KEY_RIGHT: _move(1)
			KEY_W, KEY_UP: _rotate()
			KEY_S, KEY_DOWN: _step_down()
			KEY_SPACE: _hard_drop()


func _move(dx: int) -> void:
	var np := _pivot + Vector2i(dx, 0)
	if _fits(_cells, np):
		_pivot = np
		_board.queue_redraw()


func _rotate() -> void:
	var rotated: Array = []
	for off in _cells:
		rotated.append(Vector2i(-off.y, off.x))
	if _fits(rotated, _pivot):
		_cells = rotated
		Sfx.play("swing")
		_board.queue_redraw()


func _step_down() -> void:
	var np := _pivot + Vector2i(0, 1)
	if _fits(_cells, np):
		_pivot = np
	else:
		_lock()
	_board.queue_redraw()


func _hard_drop() -> void:
	while _fits(_cells, _pivot + Vector2i(0, 1)):
		_pivot += Vector2i(0, 1)
	_lock()
	_board.queue_redraw()


func _lock() -> void:
	for off in _cells:
		var p: Vector2i = _pivot + off
		if p.y >= 0 and p.y < ROWS and p.x >= 0 and p.x < COLS:
			_grid[p.y][p.x] = _color
	Sfx.play("hit")
	_clear_lines()
	if _lines >= TARGET_LINES:
		win()
	else:
		_spawn()


func _clear_lines() -> void:
	var r := ROWS - 1
	while r >= 0:
		var full := true
		for c in COLS:
			if _grid[r][c] < 0:
				full = false
				break
		if full:
			_grid.remove_at(r)
			var blank := []
			for c in COLS:
				blank.append(-1)
			_grid.insert(0, blank)
			_lines += 1
			Sfx.play("cast_out")
			set_instruction("Rows cleared: %d / %d" % [_lines, TARGET_LINES])
		else:
			r -= 1


func _fits(cells: Array, pivot: Vector2i) -> bool:
	for off in cells:
		var p: Vector2i = pivot + off
		if p.x < 0 or p.x >= COLS or p.y >= ROWS:
			return false
		if p.y >= 0 and _grid[p.y][p.x] >= 0:
			return false
	return true


func debug_solve() -> void:
	_lines = TARGET_LINES
	win()
