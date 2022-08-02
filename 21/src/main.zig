const std = @import("std");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    // var players = [_]usize{ 4, 8 };
    var players = [_]usize{ 4, 2 };

    var turn_stack = [_]Turn{Turn{}} ** 100;
    var turn_stack_size: usize = 0;

    turn_stack[0] = Turn{
        .roll = 0,
        .multiplier = 1,
        .players = [2]Player{ .{
            .score = 0,
            .position = players[0] - 1,
        }, .{
            .score = 0,
            .position = players[1] - 1,
        } },
    };
    turn_stack_size += 1;

    var player_wins: [2]usize = [_]usize{0} ** 2;

    const multi_table = [_]usize{
        0,
        0,
        0,
        1,
        3,
        6,
        7,
        6,
        3,
        1,
    };

    // 3
    // 4 4 4
    // 5 5 5 5 5 5
    // 6 6 6 6 6 6 6
    // 7 7 7 7 7 7
    // 8 8 8
    // 9

    while (turn_stack_size > 0) {
        var turn = &turn_stack[turn_stack_size - 1];

        if (turn.roll == 49) {
            // Done with this turn sequence.
            turn_stack_size -= 1;
            continue;
        }

        const player0_roll = (turn.roll / 7) + 3;
        const player1_roll = (turn.roll % 7) + 3;
        turn.roll += 1;

        // Player 1
        var multiplier: usize = turn.multiplier * multi_table[player0_roll];
        const player0_position = (turn.players[0].position + player0_roll) % 10;
        const player0_score = turn.players[0].score + (player0_position + 1);

        if (player0_score >= 21) {
            player_wins[0] += 1 * multiplier;
            continue;
        }

        // Player 2
        multiplier *= multi_table[player1_roll];
        const player1_position = (turn.players[1].position + player1_roll) % 10;
        const player1_score = turn.players[1].score + (player1_position + 1);

        if (player1_score >= 21) {
            player_wins[1] += 1 * multiplier;
            continue;
        }

        //Neither player has won, so continue with next turn.
        var new_turn = &turn_stack[turn_stack_size];
        turn_stack_size += 1;

        new_turn.roll = 0;
        new_turn.multiplier = multiplier;

        new_turn.players[0].score = player0_score;
        new_turn.players[0].position = player0_position;

        new_turn.players[1].score = player1_score;
        new_turn.players[1].position = player1_position;
    }

    log("{any}", .{player_wins});
    log("Player1 wins {}", .{player_wins[0] / 7});
    log("Player2 wins {}", .{player_wins[1]});
}

const Player = struct {
    score: usize = 0,
    position: usize = 0,
};

const Turn = struct {
    players: [2]Player = [_]Player{Player{}} ** 2,
    roll: usize = 0,
    multiplier: usize = 1,
};

// 1 - 3 - 9 - 27 = 3^3
// 81 - 243 - 729 = 9^3

// 9^3
// Trinary

// Possible dice rolls from single player (27):
// There are only 7 unique combinations here
// 1 1 1 = 3
// 1 1 2 = 4
// 1 1 3 = 5

// 1 2 1 = 4
// 1 2 2 = 5
// 1 2 3 = 6

// 1 3 1 = 5
// 1 3 2 = 6
// 1 3 3 = 7

// 2 1 1 = 4
// 2 1 2 = 5
// 2 1 3 = 6

// 2 2 1 = 5
// 2 2 2 = 6
// 2 2 3 = 7

// 2 3 1 = 6
// 2 3 2 = 7
// 2 3 3 = 8

// 3 1 1 = 5
// 3 1 2 = 6
// 3 1 3 = 7

// 3 2 1 = 6
// 3 2 2 = 7
// 3 2 3 = 8

// 3 3 1 = 7
// 3 3 2 = 8
// 3 3 3 = 9

// 3
// 4 4 4
// 5 5 5 5 5 5
// 6 6 6 6 6 6 6
// 7 7 7 7 7 7
// 8 8 8
// 9

// Min 3, Max 10
// What is the min and max number of turns needed to finish a game (for a single player)
// Num universes = 27^(player turns)

// Target score = 21

// Example wins:
// 444 356 092 776 315
// 341 960 390 180 808