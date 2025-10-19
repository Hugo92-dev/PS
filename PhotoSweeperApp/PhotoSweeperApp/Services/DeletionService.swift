import Foundation
import PhotoSweeperCore
import UIKit

class DeletionService {
    static let shared = DeletionService()

    private init() {}

    /// Delete selected assets from groups and heuristics
    func deleteSelected(
        groups: [Group],
        heuristics: [HeuristicResult],
        completion: @escaping (Bool) -> Void
    ) {
        // Collect all asset IDs to delete
        var assetIDsToDelete = Set<String>()

        // From groups
        for group in groups {
            let toDelete = group.membersToDelete.map { $0.id }
            assetIDsToDelete.formUnion(toDelete)
        }

        // From heuristics
        for result in heuristics where result.isSelected {
            assetIDsToDelete.insert(result.assetID)
        }

        let assetIDs = Array(assetIDsToDelete)

        guard !assetIDs.isEmpty else {
            completion(false)
            return
        }

        // Perform deletion
        PhotoLibraryManager.shared.deleteAssets(assetIDs) { success, error in
            if let error = error {
                print("Deletion error: \(error)")
            }

            DispatchQueue.main.async {
                if success {
                    self.showDeletionSuccess(count: assetIDs.count)
                }
                completion(success)
            }
        }
    }

    private func showDeletionSuccess(count: Int) {
        // Show success alert with option to open Recently Deleted
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        let alert = UIAlertController(
            title: "Suppression réussie",
            message: "\(count) élément(s) ont été déplacés dans 'Supprimés récemment'. Vous pouvez les restaurer pendant 30 jours.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        alert.addAction(UIAlertAction(title: "Ouvrir 'Supprimés récemment'", style: .default) { _ in
            PhotoLibraryManager.shared.openRecentlyDeleted()
        })

        rootViewController.present(alert, animated: true)
    }
}
