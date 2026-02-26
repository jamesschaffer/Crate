import Foundation
import MusicKit

/// Namespaced utilities for weighted distribution and interleaving.
/// Used by both CrateWallService and GenreFeedService.
enum WeightedInterleave {

    /// Convert fractional weights to integer counts that sum to `total`.
    /// Uses the largest-remainder method so rounding errors don't lose items.
    static func distribute<Key: Hashable>(_ weights: [Key: Double], total: Int) -> [Key: Int] {
        let raw = weights.mapValues { $0 * Double(total) }
        var floored = raw.mapValues { Int($0) }
        let assigned = floored.values.reduce(0, +)
        var remainder = total - assigned

        let sorted = raw.sorted { ($0.value - Double(Int($0.value))) > ($1.value - Double(Int($1.value))) }
        for entry in sorted where remainder > 0 {
            floored[entry.key, default: 0] += 1
            remainder -= 1
        }

        return floored
    }

    /// Interleave albums from signal buckets so higher-weighted signals appear more
    /// frequently but aren't clustered together in long runs.
    ///
    /// Uses index cursors instead of removeFirst() to avoid O(n) array shifts.
    static func interleave<Signal: Hashable>(
        buckets: [Signal: [CrateAlbum]],
        weights: [Signal: Double]
    ) -> [CrateAlbum] {
        var queues: [Signal: [CrateAlbum]] = [:]
        for (signal, albums) in buckets {
            queues[signal] = albums.shuffled()
        }

        // Index cursors — advance instead of removeFirst() (O(1) vs O(n))
        var cursors: [Signal: Int] = [:]
        for signal in buckets.keys {
            cursors[signal] = 0
        }

        let allSignals = Array(buckets.keys)
        let totalCount = queues.values.reduce(0) { $0 + $1.count }
        var result: [CrateAlbum] = []
        result.reserveCapacity(totalCount)

        var activeSignals = allSignals.filter { (cursors[$0] ?? 0) < (queues[$0]?.count ?? 0) }

        while !activeSignals.isEmpty {
            let totalWeight = activeSignals.reduce(0.0) { $0 + (weights[$1] ?? 0) }
            guard totalWeight > 0 else { break }

            let roll = Double.random(in: 0..<totalWeight)
            var cumulative = 0.0
            var chosen = activeSignals[0]

            for signal in activeSignals {
                cumulative += weights[signal] ?? 0
                if roll < cumulative {
                    chosen = signal
                    break
                }
            }

            if let queue = queues[chosen], let cursor = cursors[chosen], cursor < queue.count {
                result.append(queue[cursor])
                cursors[chosen] = cursor + 1
            }

            activeSignals = allSignals.filter { (cursors[$0] ?? 0) < (queues[$0]?.count ?? 0) }
        }

        return result
    }
}
