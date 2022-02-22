public final actor TaskQueue {
    private var task = Task<Void, Never> { }

    public init() {}
    
    @discardableResult
    public func queueAction<T>(_ perform: @Sendable @escaping () async throws -> T) -> Task<T, Error> {
        let currentTask = self.task
        let newTask = Task<T, Error> {
            await currentTask.value
            try Task.checkCancellation()
            return try await perform()
        }
        
        self.task = Task {
            _ = try? await newTask.value
        }
        
        return newTask
    }
}
