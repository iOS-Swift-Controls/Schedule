import Foundation

extension Plan {

    /// Schedules a task with this plan.
    ///
    /// When time is up, the task will be executed on current thread. It behaves
    /// like a `Timer`, so you have to make sure the current thread has a
    /// runloop available.
    ///
    /// Since this method relies on run loop, it is recommended to use
    /// `do(queue: _, onElapse: _)`.
    ///
    /// - Parameters:
    ///   - mode: The mode in which to add the task.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    public func `do`(mode: RunLoop.Mode = .common,
                     onElapse: @escaping (Task) -> Void) -> Task {
        return RunLoopTask(plan: self, mode: mode, onElapse: onElapse)
    }

    /// Schedules a task with this plan.
    ///
    /// When time is up, the task will be executed on current thread. It behaves
    /// like a `Timer`, so you have to make sure the current thread has a
    /// runloop available.
    ///
    /// Since this method relies on run loop, it is recommended to use
    /// `do(queue: _, onElapse: _)`.
    ///
    /// - Parameters:
    ///   - mode: The mode in which to add the task.
    ///   - onElapse: The action to do when time is out.
    /// - Returns: The task just created.
    public func `do`(mode: RunLoop.Mode = .common,
                     onElapse: @escaping () -> Void) -> Task {
        return self.do(mode: mode) { (_) in
            onElapse()
        }
    }
}

private final class RunLoopTask: Task {

    var timer: Timer!

    init(plan: Plan, mode: RunLoop.Mode, onElapse: @escaping (Task) -> Void) {

        weak var this: Task?

        let distant = Date.distantFuture.timeIntervalSinceReferenceDate
        timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, distant, distant, 0, 0) { _ in
            guard let task = this else { return }
            onElapse(task)
        }

        RunLoop.current.add(timer, forMode: mode)

        super.init(plan: plan, queue: nil) { (task) in
            guard let task = task as? RunLoopTask else { return }
            task.timer.fireDate = Date()
        }

        this = self
    }

    deinit {
        timer.invalidate()
    }
}
