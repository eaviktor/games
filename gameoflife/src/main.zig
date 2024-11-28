const rl = @import("raylib");
const std = @import("std");

const Cell = struct {
    position: rl.Vector2,
    isAlive: bool,
};

const square_size = 10;
const screen_width = 800;
const screen_height = 450;
var offset: rl.Vector2 = .{ .x = 0, .y = 0 };

fn snapToGrid(pos: rl.Vector2) rl.Vector2 {
    return .{
        .x = @floor((pos.x - offset.x / 2) / square_size) * square_size + offset.x / 2,
        .y = @floor((pos.y - offset.y / 2) / square_size) * square_size + offset.y / 2,
    };
}

fn countNeighbors(cells: std.ArrayList(Cell), pos: rl.Vector2) usize {
    var count: usize = 0;
    const directions = [8][2]f32{
        [2]f32{ -1, -1 }, [2]f32{ 0, -1 }, [2]f32{ 1, -1 },
        [2]f32{ -1, 0 },  [2]f32{ 1, 0 },  [2]f32{ -1, 1 },
        [2]f32{ 0, 1 },   [2]f32{ 1, 1 },
    };

    for (directions) |dir| {
        const neighbor_pos = rl.Vector2{
            .x = pos.x + dir[0] * square_size,
            .y = pos.y + dir[1] * square_size,
        };

        for (cells.items) |cell| {
            if (cell.position.x == neighbor_pos.x and
                cell.position.y == neighbor_pos.y and
                cell.isAlive)
            {
                count += 1;
            }
        }
    }
    return count;
}

fn initGame(cells: *std.ArrayList(Cell)) !void {
    var new_cells = std.ArrayList(Cell).init(std.heap.page_allocator);
    defer new_cells.deinit();

    const rows = @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(screen_height / square_size)))));
    const cols = @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(screen_width / square_size)))));

    for (0..rows) |row| {
        for (0..cols) |col| {
            const pos = rl.Vector2{
                .x = @as(f32, @floatFromInt(col)) * square_size + offset.x / 2,
                .y = @as(f32, @floatFromInt(row)) * square_size + offset.y / 2,
            };

            var is_alive = false;
            for (cells.items) |cell| {
                if (cell.position.x == pos.x and cell.position.y == pos.y) {
                    is_alive = cell.isAlive;
                    break;
                }
            }

            const neighbors = countNeighbors(cells.*, pos);

            var is_survived = true;
            if (is_alive) {
                is_survived = (neighbors == 2) or (neighbors == 3);
            } else {
                is_survived = neighbors == 3;
            }

            if (is_survived) {
                try new_cells.append(Cell{
                    .position = pos,
                    .isAlive = true,
                });
            }
        }
    }

    cells.clearRetainingCapacity();
    try cells.appendSlice(new_cells.items);
}

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "game of life");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const s = rl.Vector2.init(square_size, square_size);
    var cells = std.ArrayList(Cell).init(std.heap.page_allocator);
    defer cells.deinit();

    var paused = true;
    var frame_count: i32 = 0;

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(rl.KeyboardKey.key_space)) {
            paused = !paused;
        }

        if (!paused) {
            frame_count += 1;
            if (frame_count >= 10) {
                try initGame(&cells);
                frame_count = 0;
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.white);

        for (0..@floor(screen_width / square_size + 1.0)) |i| {
            const line_x = @as(f32, @floatFromInt(i)) * square_size + offset.x / 2;
            rl.drawLineV(rl.Vector2.init(line_x, offset.y / 2), rl.Vector2.init(line_x, screen_height - offset.y / 2), rl.Color.light_gray);
        }
        for (0..@floor(screen_height / square_size + 1.0)) |not_i| {
            const i: f32 = @floatFromInt(not_i);
            rl.drawLineV(rl.Vector2.init(offset.x / 2, i * square_size + offset.y / 2), rl.Vector2.init(screen_width - offset.x / 2, i * square_size + offset.y / 2), rl.Color.light_gray);
        }

        for (cells.items) |value| {
            rl.drawRectangleV(value.position, s, rl.Color.black);
        }

        if (paused) {
            rl.drawText("space to unpause", 10, 10, 20, rl.Color.black);
        } else {
            rl.drawText("space to pause", 10, 10, 20, rl.Color.black);
        }

        if (paused) {
            const m = rl.getMousePosition();
            if (rl.isMouseButtonPressed(.mouse_button_left)) {
                const snapped_pos = snapToGrid(m);

                var cell_exists = false;
                for (cells.items) |cell| {
                    if (cell.position.x == snapped_pos.x and cell.position.y == snapped_pos.y) {
                        cell_exists = true;
                        break;
                    }
                }

                if (!cell_exists) {
                    try cells.append(Cell{ .position = snapped_pos, .isAlive = true });
                }
            }
        }
    }
}
