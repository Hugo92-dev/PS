import Foundation
import Vision
import CoreImage

/// Service for Vision framework feature extraction
class VisionService {
    static let shared = VisionService()

    private init() {}

    /// Extract Vision feature print from CGImage
    /// - Parameter cgImage: Source image
    /// - Returns: Feature print data (descriptor) or nil if extraction fails
    func extractFeaturePrint(from cgImage: CGImage) async -> Data? {
        return await withCheckedContinuation { continuation in
            // Create Vision request
            let request = VNGenerateImageFeaturePrintRequest()

            // Create request handler
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                // Perform request
                try handler.perform([request])

                // Get results
                guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(returning: nil)
                    return
                }

                // Extract descriptor data
                let descriptor = observation.data
                continuation.resume(returning: descriptor)

            } catch {
                print("Vision feature print extraction failed: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }

    /// Compute distance between two feature print descriptors
    /// - Parameters:
    ///   - descriptor1: First feature print data
    ///   - descriptor2: Second feature print data
    /// - Returns: Distance (0.0 = identical, 1.0 = completely different)
    func computeDistance(between descriptor1: Data, and descriptor2: Data) -> Float? {
        do {
            // Create feature print observations from data
            let observation1 = try VNFeaturePrintObservation(data: descriptor1)
            let observation2 = try VNFeaturePrintObservation(data: descriptor2)

            // Compute distance
            var distance: Float = 0
            try observation1.computeDistance(&distance, to: observation2)

            return distance

        } catch {
            print("Failed to compute Vision distance: \(error)")
            return nil
        }
    }

    /// Extract feature print from UIImage
    func extractFeaturePrint(from uiImage: UIImage) async -> Data? {
        guard let cgImage = uiImage.cgImage else { return nil }
        return await extractFeaturePrint(from: cgImage)
    }
}
