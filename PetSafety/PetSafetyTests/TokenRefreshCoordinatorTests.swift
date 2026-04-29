import Testing
import Foundation
@testable import PetSafety

/// Regression tests for `TokenRefreshCoordinator` — the actor that funnels
/// concurrent 401-handling refreshes into a single network roundtrip
/// (audit H50). Mirrors the web `TokenRefreshCoordinator` test contract
/// and the Android `TokenAuthenticator` synchronized block so an outage on
/// the refresh path looks the same on every client.
@Suite("TokenRefreshCoordinator")
struct TokenRefreshCoordinatorTests {

    typealias TokenPair = (accessToken: String, refreshToken: String)

    /// Counts how many times the closure ran, so we can assert single-flight.
    actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }

    @Test("Single in-flight refresh — N concurrent callers see one closure invocation")
    func testSingleFlight() async throws {
        let coordinator = TokenRefreshCoordinator()
        let counter = CallCounter()

        // 50 concurrent callers race the refresh. Only one closure run.
        let result = try await withThrowingTaskGroup(of: TokenPair.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try await coordinator.refresh {
                        await counter.increment()
                        // Tiny delay so callers actually overlap rather
                        // than each completing before the next starts.
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                        return (accessToken: "shared-token", refreshToken: "shared-refresh")
                    }
                }
            }
            var collected: [TokenPair] = []
            for try await pair in group { collected.append(pair) }
            return collected
        }

        let runs = await counter.count
        #expect(runs == 1, "Closure must run exactly once for 50 racing callers, ran \(runs)x")
        #expect(result.count == 50, "All 50 callers should receive a result")
        #expect(result.allSatisfy { $0.accessToken == "shared-token" })
    }

    @Test("All waiters see the same rejection when refresh throws")
    func testFanOutFailure() async {
        let coordinator = TokenRefreshCoordinator()
        let counter = CallCounter()
        struct RefreshFailure: Error, Equatable { let kind: String }
        let failure = RefreshFailure(kind: "expired")

        var rejections = 0
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        _ = try await coordinator.refresh {
                            await counter.increment()
                            try await Task.sleep(nanoseconds: 5_000_000) // 5ms
                            throw failure
                        }
                        return false
                    } catch let err as RefreshFailure {
                        return err == failure
                    } catch {
                        return false
                    }
                }
            }
            for await sawSameFailure in group {
                if sawSameFailure { rejections += 1 }
            }
        }

        let runs = await counter.count
        #expect(runs == 1, "Closure must run exactly once even on failure, ran \(runs)x")
        #expect(rejections == 10, "All 10 waiters should observe the same rejection")
    }

    @Test("In-flight slot clears after success so a future refresh can proceed")
    func testSlotClearsAfterSuccess() async throws {
        let coordinator = TokenRefreshCoordinator()
        let counter = CallCounter()

        let first = try await coordinator.refresh {
            await counter.increment()
            return (accessToken: "first", refreshToken: "r1")
        }
        let second = try await coordinator.refresh {
            await counter.increment()
            return (accessToken: "second", refreshToken: "r2")
        }

        #expect(first.accessToken == "first")
        #expect(second.accessToken == "second")
        let runs = await counter.count
        #expect(runs == 2, "Sequential calls should each invoke the closure")
    }

    @Test("In-flight slot clears after failure so a retry can proceed")
    func testSlotClearsAfterFailure() async throws {
        let coordinator = TokenRefreshCoordinator()
        struct Transient: Error {}

        do {
            _ = try await coordinator.refresh { throw Transient() }
            Issue.record("First refresh should have thrown")
        } catch is Transient {
            // Expected
        }

        let recovered = try await coordinator.refresh {
            return (accessToken: "recovered", refreshToken: "r")
        }
        #expect(recovered.accessToken == "recovered")
    }
}
