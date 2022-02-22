/// A queue that executes queued tasks serially, in the order they are queued.
public final actor TaskQueue {
    private var task = Task<Void, Never> { }

    /// Creates a new task group.
    public init() {}
    
    /// Queue the given `work` in the task queue, waiting for any previously queued units of work to finish before executing the `work.`
    ///
    /// - Returns: The task representing the asynchronous `work`. The execution of `work` can be prevented by cancelling the returned task before the `work` is executed.
    @discardableResult
    public func queueThrowingAction<T>(_ work: @Sendable @escaping () async throws -> T) -> Task<T, Error> {
        let currentTask = self.task
        let newTask = Task<T, Error> {
            await currentTask.value
            try Task.checkCancellation()
            return try await work()
        }
        
        self.task = Task {
            _ = try? await newTask.value
        }
        
        return newTask
    }
    
    /// Queue the given `work` in the task queue, waiting for any previously queued units of work to finish before executing the `work.`
    ///
    /// - Returns: The task representing the asynchronous `work`.
    @discardableResult
    public func queueAction<T>(_ work: @Sendable @escaping () async -> T) -> Task<T, Never> {
        let currentTask = self.task
        let newTask = Task<T, Never> {
            await currentTask.value
            return await work()
        }
        
        self.task = Task {
            _ = await newTask.value
        }
        
        return newTask
    }
    
    /// Run the given `work` in the task queue, waiting for any previously queued units of work to finish before executing the `work.`
    ///
    /// - Returns: The return value of `work`.
    public func run<T>(_ work: @Sendable @escaping () async -> T) async -> T {
        await queueAction(work).value
    }
    
    /// Run the given `work` in the task queue, waiting for any previously queued units of work to finish before executing the `work.`
    /// 
    /// - Returns: The return value of `work`.
    public func runThrowing<T>(_ work: @Sendable @escaping () async throws -> T) async throws -> T {
        try await queueThrowingAction(work).value
    }
}
