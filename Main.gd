extends Control

const COLS := 10
const ROWS := 20
const BG := Color("#090e20")
const PANEL := Color("#141c35")
const GRID := Color("#27324f")
const COLORS := [
    Color("#42d9ff"), Color("#4f7cff"), Color("#ff9e43"),
    Color("#ffe15b"), Color("#5ee38d"), Color("#b17aff"),
    Color("#ff5f83")
]
const SHAPES := [
    [Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1)], # I
    [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], # J
    [Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], # L
    [Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(2,1)], # O
    [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)], # S
    [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)], # T
    [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)]  # Z
]

var board: Array = []
var current_type := 0
var current_cells: Array = []
var piece_x := 3
var piece_y := 0
var next_type := 0
var score := 0
var lines := 0
var best_score := 0
var fall_timer := 0.0
var fall_interval := 0.72
var paused := false
var game_over := false
var rng := RandomNumberGenerator.new()
var buttons: Dictionary = {}
var touch_start := Vector2.ZERO
var touch_active := false

func _ready() -> void:
    rng.randomize()
    best_score = int(load_best())
    reset_game()
    set_process(true)
    queue_redraw()

func load_best() -> int:
    var cfg := ConfigFile.new()
    if cfg.load("user://blockdrop.cfg") == OK:
        return int(cfg.get_value("scores", "best", 0))
    return 0

func save_best() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("scores", "best", best_score)
    cfg.save("user://blockdrop.cfg")

func reset_game() -> void:
    board.clear()
    for y in range(ROWS):
        var row: Array = []
        for x in range(COLS):
            row.append(-1)
        board.append(row)
    score = 0
    lines = 0
    fall_timer = 0.0
    fall_interval = 0.72
    paused = false
    game_over = false
    next_type = rng.randi_range(0, SHAPES.size() - 1)
    spawn_piece()
    queue_redraw()

func spawn_piece() -> void:
    current_type = next_type
    next_type = rng.randi_range(0, SHAPES.size() - 1)
    current_cells = SHAPES[current_type].duplicate()
    piece_x = 3
    piece_y = -1
    if not can_place(piece_x, piece_y, current_cells):
        game_over = true
        if score > best_score:
            best_score = score
            save_best()

func can_place(px: int, py: int, cells: Array) -> bool:
    for cell in cells:
        var bx: int = px + int(cell.x)
        var by: int = py + int(cell.y)
        if bx < 0 or bx >= COLS or by >= ROWS:
            return false
        if by >= 0 and board[by][bx] != -1:
            return false
    return true

func lock_piece() -> void:
    for cell in current_cells:
        var bx: int = piece_x + int(cell.x)
        var by: int = piece_y + int(cell.y)
        if by >= 0 and by < ROWS and bx >= 0 and bx < COLS:
            board[by][bx] = current_type
    clear_lines()
    spawn_piece()

func clear_lines() -> void:
    var cleared := 0
    for y in range(ROWS - 1, -1, -1):
        var full := true
        for x in range(COLS):
            if board[y][x] == -1:
                full = false
                break
        if full:
            board.remove_at(y)
            var empty: Array = []
            for x in range(COLS):
                empty.append(-1)
            board.insert(0, empty)
            cleared += 1
    if cleared > 0:
        var points := [0, 100, 300, 500, 800]
        score += points[mini(cleared, 4)] * maxi(1, int(1 + lines / 10))
        lines += cleared
        fall_interval = maxf(0.12, 0.72 - float(lines) * 0.018)
        if score > best_score:
            best_score = score
            save_best()

func move_piece(dx: int, dy: int) -> void:
    if paused or game_over:
        return
    if can_place(piece_x + dx, piece_y + dy, current_cells):
        piece_x += dx
        piece_y += dy
    elif dy > 0:
        lock_piece()
    queue_redraw()

func rotate_piece() -> void:
    if paused or game_over or current_type == 3:
        return
    var rotated: Array = []
    var max_x := 0
    var max_y := 0
    for c in current_cells:
        max_x = maxi(max_x, int(c.x))
        max_y = maxi(max_y, int(c.y))
    for c in current_cells:
        rotated.append(Vector2i(max_y - int(c.y), int(c.x)))
    var min_x := 999
    var min_y := 999
    for c in rotated:
        min_x = mini(min_x, int(c.x))
        min_y = mini(min_y, int(c.y))
    for i in range(rotated.size()):
        rotated[i] = Vector2i(rotated[i].x - min_x, rotated[i].y - min_y)
    for kick in [0, -1, 1, -2, 2]:
        if can_place(piece_x + kick, piece_y, rotated):
            piece_x += kick
            current_cells = rotated
            queue_redraw()
            return

func hard_drop() -> void:
    if paused or game_over:
        return
    while can_place(piece_x, piece_y + 1, current_cells):
        piece_y += 1
        score += 2
    lock_piece()
    queue_redraw()

func _process(delta: float) -> void:
    if paused or game_over:
        return
    fall_timer += delta
    if fall_timer >= fall_interval:
        fall_timer = 0.0
        move_piece(0, 1)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_LEFT: move_piece(-1, 0)
            KEY_RIGHT: move_piece(1, 0)
            KEY_DOWN: move_piece(0, 1)
            KEY_UP, KEY_X: rotate_piece()
            KEY_SPACE: hard_drop()
            KEY_P: paused = not paused
            KEY_R: reset_game()
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            touch_start = event.position
        elif touch_active:
            touch_active = false
            var delta: Vector2 = event.position - touch_start
            if absf(delta.x) > 28 or absf(delta.y) > 28:
                if absf(delta.x) > absf(delta.y):
                    move_piece(1 if delta.x > 0 else -1, 0)
                elif delta.y > 0:
                    move_piece(0, 1)
                else:
                    rotate_piece()
            else:
                handle_tap(event.position)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        handle_tap(event.position)

func handle_tap(pos: Vector2) -> void:
    if game_over:
        if buttons.get("restart", Rect2()).has_point(pos):
            reset_game()
        queue_redraw()
        return
    for key in buttons:
        if buttons[key].has_point(pos):
            match key:
                "left": move_piece(-1, 0)
                "right": move_piece(1, 0)
                "down": move_piece(0, 1)
                "rotate": rotate_piece()
                "drop": hard_drop()
                "pause": paused = not paused
                "restart": reset_game()
            queue_redraw()
            return

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()

func _draw() -> void:
    var s := size
    draw_rect(Rect2(Vector2.ZERO, s), BG)
    var w := s.x
    draw_string(ThemeDB.fallback_font, Vector2(22, 38), "BLOCKDROP", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("#f5f7ff"))
    draw_string(ThemeDB.fallback_font, Vector2(23, 61), "FALLING BLOCK PUZZLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#8f9bbb"))

    var cell := floorf(minf((w - 36.0) / COLS, (s.y - 330.0) / ROWS))
    cell = clampf(cell, 13.0, 30.0)
    var board_w := cell * COLS
    var board_h := cell * ROWS
    var bx := (w - board_w) / 2.0
    var by := 112.0
    if by + board_h > s.y - 180:
        by = maxf(75.0, s.y - 180.0 - board_h)
    draw_rect(Rect2(bx - 5, by - 5, board_w + 10, board_h + 10), PANEL, true, 12.0)
    draw_rect(Rect2(bx, by, board_w, board_h), Color("#0c1328"))

    for y in range(ROWS):
        for x in range(COLS):
            var rect := Rect2(bx + x * cell + 1, by + y * cell + 1, cell - 2, cell - 2)
            var val: int = board[y][x]
            if val >= 0:
                draw_block(rect, COLORS[val])
            else:
                draw_rect(rect, GRID, true, 3.0)

    if not game_over:
        for c in current_cells:
            var px: int = piece_x + int(c.x)
            var py: int = piece_y + int(c.y)
            if py >= 0:
                draw_block(Rect2(bx + px * cell + 1, by + py * cell + 1, cell - 2, cell - 2), COLORS[current_type])

    var info_y := by + board_h + 28
    draw_string(ThemeDB.fallback_font, Vector2(22, info_y), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8f9bbb"))
    draw_string(ThemeDB.fallback_font, Vector2(22, info_y + 30), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#ffffff"))
    draw_string(ThemeDB.fallback_font, Vector2(w * 0.43, info_y), "LINES", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8f9bbb"))
    draw_string(ThemeDB.fallback_font, Vector2(w * 0.43, info_y + 30), str(lines), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#ffffff"))
    draw_string(ThemeDB.fallback_font, Vector2(w - 100, info_y), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8f9bbb"))
    draw_string(ThemeDB.fallback_font, Vector2(w - 100, info_y + 30), str(best_score), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#ffffff"))

    var controls_y := s.y - 100
    var gap := 8.0
    var bw := (w - 44.0 - gap * 4) / 5.0
    var labels := ["◀", "▶", "▼", "ROT", "DROP"]
    var keys := ["left", "right", "down", "rotate", "drop"]
    buttons.clear()
    for i in range(keys.size()):
        var r := Rect2(22 + i * (bw + gap), controls_y, bw, 54)
        buttons[keys[i]] = r
        draw_rect(r, Color("#1b2747"), true, 10.0)
        draw_rect(r, Color("#34466e"), false, 1.5)
        draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.position.y + 33), labels[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17 if i < 3 else 11, Color("#eef3ff"))

    var small_y := s.y - 34
    buttons["pause"] = Rect2(22, small_y - 18, 100, 25)
    buttons["restart"] = Rect2(w - 122, small_y - 18, 100, 25)
    draw_string(ThemeDB.fallback_font, Vector2(22, small_y), "Ⅱ  PAUSE", HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("#a8b5d6"))
    draw_string(ThemeDB.fallback_font, Vector2(w - 122, small_y), "↻  RESTART", HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("#a8b5d6"))

    if paused or game_over:
        draw_rect(Rect2(0, 0, w, s.y), Color(0, 0, 0, 0.68))
        var headline := "GAME OVER" if game_over else "PAUSED"
        draw_string(ThemeDB.fallback_font, Vector2(0, s.y * 0.47), headline, HORIZONTAL_ALIGNMENT_CENTER, w, 30, Color("#ffffff"))
        var sub := "Tap RESTART to play again" if game_over else "Tap PAUSE to continue"
        draw_string(ThemeDB.fallback_font, Vector2(0, s.y * 0.47 + 32), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 13, Color("#b8c5e6"))

func draw_block(rect: Rect2, color: Color) -> void:
    draw_rect(rect, color, true, 4.0)
    var shine := color.lightened(0.22)
    draw_line(rect.position + Vector2(4, 3), rect.position + Vector2(rect.size.x - 4, 3), shine, 2.0)
    draw_line(rect.position + Vector2(3, 4), rect.position + Vector2(3, rect.size.y - 4), shine, 2.0)
