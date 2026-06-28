fn compute_inv(p: u32) u32 {
    var result: u32 = 0;
    var t: u32 = 0;
    for (0..32) |i_usize| {
        const i: u5 = @intCast(i_usize);
        if (t & 1 == 0) {
            t = t +% p;
            result |= @as(u32, 1) << i;
        }
        t >>= 1;
    }
    return result;
}

fn compute_r2(p: u32) u32 {
    const p64 = @as(u64, p);
    return @intCast(-%p64 % p64);
}

pub fn FpMontgomery(comptime p: u32) type {
    return struct {
        mont_value: u64,

        const p64: u64 = p;
        const k = compute_inv(p);
        const r2 = -%p64 % p64;

        const Self = @This();

        fn reduce(value: u64) u64 {
            const value_u32: u32 = @intCast(value & ((1 << 32) - 1));
            const value_mul_k: u64 = @as(u64, value_u32 *% k);
            var result = (value_mul_k * p64 + value) >> 32;
            if (p <= result) result -= p;
            return result;
        }

        pub fn init(value: u64) Self {
            return .{ .mont_value = Self.reduce(value % p * r2) };
        }

        pub fn standard_value(self: Self) u32 {
            return @intCast(Self.reduce(self.mont_value));
        }

        pub fn addAssign(self: *Self, other: Self) void {
            self.*.mont_value += other.mont_value;
        }

        pub fn mul(self: Self, other: Self) Self {
            const a: u64 = self.mont_value;
            const b: u64 = other.mont_value;
            return .{ .mont_value = Self.reduce(a * b) };
        }
    };
}

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
