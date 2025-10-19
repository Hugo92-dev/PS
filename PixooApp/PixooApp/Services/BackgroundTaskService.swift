import Foundation
import BackgroundTasks
import PixooCore

class BackgroundTaskService {
    static let shared = BackgroundTaskService()

    private static let taskIdentifier = "com.pixoo.app.scan"

    private init() {}

    /// Register background tasks on app launch
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleScanTask(task as! BGProcessingTask)
        }
    }

    /// Schedule background scan task
    func scheduleBackgroundScan() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Allow system to run anytime
        request.earliestBeginDate = nil

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background scan scheduled")
        } catch {
            print("Failed to schedule background scan: \(error)")
        }
    }

    /// Cancel scheduled background scan
    func cancelBackgroundScan() {
        BGTaskScheduler.shared.cancel(taskWithIdentifier: Self.taskIdentifier)
    }

    // MARK: - Private

    private func handleScanTask(_ task: BGProcessingTask) {
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            do {
                // Check if there's a paused scan
                let sweeper = Sweeper(config: .default)
                guard let progress = try? sweeper.loadScanState(),
                      progress.status == .paused || progress.status == .running,
                      progress.processedCount < progress.totalCount else {
                    task.setTaskCompleted(success: true)
                    return
                }

                // Resume scan
                let scanService = await ScanService.shared
                await scanService.startScan { groups, heuristics, assets in
                    // Save results
                    try? sweeper.saveGroups(groups)
                    try? sweeper.saveHeuristics(heuristics)

                    // Send notification
                    let savings = sweeper.estimatedSavings(
                        groups: groups,
                        heuristics: heuristics,
                        assets: assets
                    )
                    NotificationService.shared.sendScanCompletedNotification(
                        processedCount: progress.totalCount,
                        savings: savings
                    )

                    task.setTaskCompleted(success: true)
                }
            } catch {
                print("Background scan error: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        // Schedule next run
        scheduleBackgroundScan()
    }
}

// MARK: - e-TaskScheduler Extension for testing

#if DEBUG
extension BGTaskScheduler {
    /// Simulate background task launch (use in debugger with: e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.photosweeper.scan"])
    /// Or via Xcode: Debug → Simulate Background Fetch
}
#endif
