const std = @import("std");

pub fn MinPriorityQueue(T: type) type {
    return std.PriorityQueue(T, void, struct {
        fn inner(_: void, lhs: T, rhs: T) std.math.Order {
            return std.math.order(lhs, rhs).invert();
        }
    }.inner);
}

pub fn MaxPriorityQueue(T: type) type {
    return std.PriorityQueue(T, void, struct {
        fn inner(_: void, lhs: T, rhs: T) std.math.Order {
            return std.math.order(lhs, rhs);
        }
    }.inner);
}
