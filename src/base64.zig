const std = @import("std");
const print = std.debug.print;

pub fn printBits(c: u8) void {
    for (0..8) |i| {
        const shift: u3 = @intCast(7 - i);
        const bit = (c >> shift) & 1;
        print("{d}", .{bit});
    }
    print("\n", .{});
}

pub const Base64 = struct {
    _table: *const [64]u8,

    pub fn inint() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    pub fn encode(
        self: Base64,
        allocator: std.mem.Allocator, 
        input: []const u8
        ) ![]u8 {
        const size = try Base64._calc_encode_length(input);
        var out = try allocator.alloc(u8, size);
        if (size == 0) return out;

        var buf = [3]u8{0, 0, 0};

        var count: u8 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iout] = self._char_at(buf[0] >> 2);
                out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) | (buf[1] >> 4));
                out[iout + 2] = self._char_at(((buf[1] & 0x0F) << 2) | (buf[2] >> 6));
                out[iout + 3] = self._char_at(buf[2] & 0x3F);
                iout += 4;
                count = 0;
            }
        }
        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0x03) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }
        else if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) | (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0x0F) << 2);
            out[iout + 3] = '=';
        }

        return out;
        }
    
    pub fn decode(
        self: Base64,
        allocator: std.mem.Allocator, 
        input: []const u8
        ) ![]u8 {
            const size = try Base64._calc_decode_length(input);
            var out = try allocator.alloc(u8, size);
            if (size == 0) return out;

            var buf = [4]u8{0, 0, 0, 0};
            var count: u8 = 0;
            var iout: u64 = 0;

            for (0..input.len) |i| {
                buf[count] = self._char_index(input[i]);
                count += 1;
                if (count == 4) {
                    out[iout] = (buf[0] << 2) | (buf[1] >> 4);
                    if (buf[2] != 64) out[iout + 1] = (buf[1] << 4) | (buf[2] >> 2);
                    if (buf[3] != 64) out[iout + 2] = (buf[2] << 6) | buf[3];
                    iout += 3;
                    count = 0;
                }
            }

            return out;
        }

    pub fn _calc_encode_length(input: []const u8) !usize {
        if (input.len == 0) return 0;
        if (input.len < 3) return 4;
        
        const n_groups: usize = try std.math.divCeil(
            usize, input.len, 3
        );
        return n_groups * 4;
    }

    pub fn _calc_decode_length(input: []const u8) !usize {
        if (input.len == 0) return 0;
        if (input.len < 4) return 3;

        const n_groups = try std.math.divFloor(
            usize, input.len, 4
        );
        var multiple_groups = n_groups * 3;
        var i: usize = input.len - 1;

        while (i>0) : (i-=1) {
            if (input[i] == '=') {
                multiple_groups -= 1;
            } else {
                break;
            }
        }

        return multiple_groups;
    }
    
    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    pub fn _char_index(self: Base64, char: u8) u8 {
        // TODO: kinda shitty func, rewrite.
        if (char == '=') return 64;
        var index: u8 = 0;
        for (0..63) |i| {
            if (self._char_at(i) == char)
                break;
            index += 1;
        }

        return index;
    }
};
