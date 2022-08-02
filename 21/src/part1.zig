const std = @import("std");
const log = std.log.info;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    var scores = [_]i64{ 0, 0 };
    
    // var players = [_]i64{ 4, 8 };
    var players = [_]i64{ 4, 2 };

    var die_rolls: usize = 0;
    var turn_iter: usize = 0;
    outer: while (turn_iter < 1000) : (turn_iter += 1) {
        log("Turn {}:", .{turn_iter});
        log("Players: {any} {any}", .{ players, scores });

        for (players) |*pos, player_index| {
            var roll: usize = (die_rolls % 100) + 1;
            die_rolls += 1;

            roll += (die_rolls % 100) + 1;
            die_rolls += 1;

            roll += (die_rolls % 100) + 1;
            die_rolls += 1;

            log("Player {} rolls {}", .{ player_index + 1, roll });
            pos.* = @mod((pos.* + @intCast(i64, roll) - 1), 10) + 1;
            scores[player_index] += pos.*;

            if (scores[player_index] >= 1000) {
                const losing_score = scores[players.len - player_index - 1];
                const final_value = losing_score * @intCast(i64, die_rolls);
                log("Player {} after {} rolls, losing player has {} points. Final value {}", .{ player_index + 1, die_rolls, losing_score, final_value });
                break :outer;
            }
        }
    }
}
