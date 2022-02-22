import XCTest
@testable import TaskQueue

final class TaskQueueTests: XCTestCase {
    func testTaskExecutionOrder() async {
        let queue = TaskQueue()
        
        let expectations = (1...10).map { _ -> XCTestExpectation in
            let expectation = XCTestExpectation()
            expectation.assertForOverFulfill = true
            return expectation
        }
        
        // This test works by having the first-queued tasks wait the longest, thereby testing execution order.
        for index in 1...10 {
            await queue.queueThrowingAction {
                let waitInterval = 1_000_000_000 / UInt64(index)
                try await Task.sleep(nanoseconds: waitInterval)
                expectations[index - 1].fulfill()
            }
        }
        
        wait(for: expectations, timeout: 10, enforceOrder: true)
    }
}
