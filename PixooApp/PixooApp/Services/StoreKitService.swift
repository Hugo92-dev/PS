import Foundation
import StoreKit

@MainActor
class StoreKitService: ObservableObject {
    static let productID = "com.pixoo.app.pro.lifetime"

    @Published var product: Product?
    @Published var purchasedProducts: Set<String> = []
    @Published var purchaseInProgress = false

    var isPro: Bool {
        purchasedProducts.contains(Self.productID)
    }

    init() {
        Task {
            await loadProducts()
            await loadPurchasedProducts()
        }
    }

    /// Load available products from StoreKit
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Check purchased products
    func loadPurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProducts = purchased

        // Also check UserDefaults for testing
        if UserDefaults.standard.bool(forKey: "isPro") {
            purchasedProducts.insert(Self.productID)
        }
    }

    /// Purchase product
    func purchase() async throws {
        guard let product = product else {
            throw StoreError.productNotFound
        }

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                // Grant access
                purchasedProducts.insert(transaction.productID)
                UserDefaults.standard.set(true, forKey: "isPro")

                // Finish transaction
                await transaction.finish()

                return

            case .unverified:
                throw StoreError.verificationFailed
            }

        case .userCancelled:
            throw StoreError.userCancelled

        case .pending:
            throw StoreError.purchasePending

        @unknown default:
            throw StoreError.unknown
        }
    }

    /// Restore purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadPurchasedProducts()
    }

    enum StoreError: LocalizedError {
        case productNotFound
        case verificationFailed
        case userCancelled
        case purchasePending
        case unknown

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Produit non trouvé"
            case .verificationFailed:
                return "Échec de la vérification de l'achat"
            case .userCancelled:
                return "Achat annulé"
            case .purchasePending:
                return "Achat en attente d'approbation"
            case .unknown:
                return "Erreur inconnue"
            }
        }
    }
}
