pub fn FpBase(comptime p: u64) type {
    return struct {
        value: u64,

        const Self = @This();

        pub fn init(value: u64) Self {
            return .{ .value = value % p };
        }

        pub fn addAssign(self: *Self, other: Self) void {
            self.*.value += other.value;
            if (self.*.value >= p) self.*.value -= p;
        }

        pub fn mul(self: Self, other: Self) Self {
            return .{ .value = self.value * other.value % p };
        }
    };
}
