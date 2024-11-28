const rl = @import("raylib");
const std = @import("std");

const Snake = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    speed: rl.Vector2,
    color: rl.Color,
};
const Food = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    active: bool,
    color: rl.Color,
};
const screen_width: i32 = 800;
const screen_height: i32 = 450;

const snake_length: f32 = 256;
const square_size: f32 = 20;

var frames_counter: f32 = 0;
var game_over = false;
var pause = false;
var allow_move = false;
var counter_tail: usize = 0;
var offset: rl.Vector2 = .{ .x = 0, .y = 0 };
var fruit: Food = .{
    .position = .{ .x = 0, .y = 0 },
    .size = .{ .x = 0, .y = 0 },
    .active = false,
    .color = rl.Color.init(0, 0, 0, 0),
};
var snake: [snake_length]Snake = std.mem.zeroes([snake_length]Snake);
var snake_position: [snake_length]rl.Vector2 = std.mem.zeroes([snake_length]rl.Vector2);
pub fn updateGame() void {
    if (!game_over) {
        if (rl.isKeyPressed(rl.KeyboardKey.key_p)) {
            pause = !pause;
        }
        if (!pause) {
            if (rl.isKeyPressed(.key_right) and snake[0].speed.x == 0 and allow_move) {
                snake[0].speed = .{ .x = square_size, .y = 0 };
                allow_move = false;
            }
            if (rl.isKeyPressed(.key_left) and snake[0].speed.x == 0 and allow_move) {
                snake[0].speed = .{ .x = -square_size, .y = 0 };
                allow_move = false;
            }
            if (rl.isKeyPressed(.key_up) and snake[0].speed.y == 0 and allow_move) {
                snake[0].speed = .{ .x = 0, .y = -square_size };
                allow_move = false;
            }
            if (rl.isKeyPressed(.key_down) and snake[0].speed.y == 0 and allow_move) {
                snake[0].speed = .{ .x = 0, .y = square_size };
                allow_move = false;
            }
            for (0..counter_tail) |i| {
                snake_position[i] = snake[i].position;
            }
            if (@rem(frames_counter, 5) == 0) {
                for (0..counter_tail) |i| {
                    if (i == 0) {
                        snake[0].position.x += snake[0].speed.x;
                        snake[0].position.y += snake[0].speed.y;
                        allow_move = true;
                    } else {
                        snake[i].position = snake_position[i - 1];
                    }
                }
            }
            if ((snake[0].position.x > (screen_width - offset.x)) or
                (snake[0].position.y > (screen_height - offset.y)) or
                ((snake[0].position.x < 0) or (snake[0].position.y < 0)))
            {
                game_over = true;
            }
            for (1..counter_tail) |i| {
                if ((snake[0].position.x == snake[i].position.x) and
                    (snake[0].position.y == snake[i].position.y))
                {
                    game_over = true;
                }
            }
            if (!fruit.active) {
                fruit.active = true;
                const square_size_i32: i32 = @intFromFloat(square_size);
                const max_x: i32 = @intFromFloat(screen_width / square_size - 1);
                const max_y: i32 = @intFromFloat(screen_height / square_size - 1);

                fruit.position = .{
                    .x = @as(f32, @floatFromInt(rl.getRandomValue(0, max_x) * square_size_i32)) + offset.x / 2,
                    .y = @as(f32, @floatFromInt(rl.getRandomValue(0, max_y) * square_size_i32)) + offset.y / 2,
                };
                var i: usize = 0;
                while (i < counter_tail) : (i += 1) {
                    while (fruit.position.x == snake[i].position.x and fruit.position.y == snake[i].position.y) {
                        fruit.position = .{
                            .x = @as(f32, @floatFromInt(rl.getRandomValue(0, max_x) * square_size_i32)) + offset.x / 2,
                            .y = @as(f32, @floatFromInt(rl.getRandomValue(0, max_y) * square_size_i32)) + offset.y / 2,
                        };
                        i = 0;
                    }
                }
            }

            if (snake[0].position.x < (fruit.position.x + fruit.size.x) and ((snake[0].position.x + snake[0].size.x) > fruit.position.x) and
                (snake[0].position.y < (fruit.position.y + fruit.size.y) and (snake[0].position.y + snake[0].size.y) > fruit.position.y))
            {
                snake[counter_tail].position = snake_position[counter_tail - 1];
                counter_tail += 1;
                fruit.active = false;
            }
            frames_counter += 1;
        }
    } else {
        if (rl.isKeyPressed(rl.KeyboardKey.key_enter)) {
            initGame();
            game_over = false;
        }
    }
}
pub fn initGame() void {
    frames_counter = 0;
    game_over = false;
    pause = false;

    counter_tail = 1;
    allow_move = false;

    offset.x = (screen_width % square_size);
    offset.y = (screen_height % square_size);

    for (0..snake_length) |i| {
        snake[i].position = rl.Vector2.init(offset.x / 2, offset.y / 2);
        snake[i].size = rl.Vector2.init(square_size, square_size);
        snake[i].speed = rl.Vector2.init(square_size, 0);

        if (i == 0) {
            snake[i].color = rl.Color.dark_blue;
        } else {
            snake[i].color = rl.Color.blue;
        }
    }
    for (0..snake_length) |i| {
        snake_position[i] = rl.Vector2.init(0, 0);
    }
    fruit.size = rl.Vector2.init(square_size, square_size);
    fruit.color = rl.Color.sky_blue;
    fruit.active = false;
}

pub fn drawGame() void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.ray_white);
    if (!game_over) {
        for (0..@floor(screen_width / square_size + 1.0)) |i| {
            const line_x = @as(f32, @floatFromInt(i)) * square_size + offset.x / 2;
            rl.drawLineV(rl.Vector2.init(line_x, offset.y / 2), rl.Vector2.init(line_x, screen_height - offset.y / 2), rl.Color.light_gray);
        }
        for (0..@floor(screen_height / square_size + 1.0)) |not_i| {
            const i: f32 = @floatFromInt(not_i);

            rl.drawLineV(rl.Vector2.init(offset.x / 2, i * square_size + offset.y / 2), rl.Vector2.init(screen_width - offset.x / 2, i * square_size + offset.y / 2), rl.Color.light_gray);
        }
        for (0..counter_tail) |i| {
            rl.drawRectangleV(snake[i].position, snake[i].size, snake[i].color);
        }
        rl.drawRectangleV(fruit.position, fruit.size, fruit.color);
    } else {
        rl.drawText("PRESS [ENTER] TO PLAY AGAIN", screen_width / 2 - 140, screen_height / 2 - 10, 20, rl.Color.gray);
    }
}

pub fn updateDrawFrame() void {
    updateGame();
    drawGame();
}
pub fn main() anyerror!void {
    rl.initWindow(screen_width, screen_height, "raylib-zig snake game");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    initGame();

    while (!rl.windowShouldClose()) {
        updateDrawFrame();
    }
}
