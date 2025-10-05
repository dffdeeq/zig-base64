const std = @import("std");
const first = @import("first");
const print = std.debug.print;
const base64 = @import("base64.zig");

pub fn main() !void {
    const base = base64.Base64.inint();
    
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const alloc = fba.allocator();

    print("Char at index 29: {c}\n\n", .{base._char_at(29)});

    const text = "Gamarjobat";
    const res = try base.encode(alloc, text);

    print("res: {s}", .{res});

    print("\n", .{});
}
