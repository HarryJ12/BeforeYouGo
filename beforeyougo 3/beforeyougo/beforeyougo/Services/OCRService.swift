import Foundation
import Vision
import UIKit

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    // MARK: - Extract Text from Image
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Extract Insurance Info
    func extractInsuranceInfo(frontImage: UIImage, backImage: UIImage?) async throws -> InsuranceInfo {
        let frontText = try await extractText(from: frontImage)
        var backText = ""
        if let backImage = backImage {
            backText = try await extractText(from: backImage)
        }
        
        let combinedText = frontText + "\n" + backText
        
        // Basic pattern matching for insurance fields
        let provider = extractField(from: combinedText, patterns: ["BlueCross", "Aetna", "UnitedHealthcare", "Cigna", "Humana", "Kaiser", "Anthem"])
        let memberID = extractPattern(from: combinedText, pattern: #"(?i)(?:member|id|subscriber)\s*(?:id|#|number)?:?\s*([A-Z0-9]{6,})"#)
        let groupNumber = extractPattern(from: combinedText, pattern: #"(?i)(?:group)\s*(?:#|number|no)?:?\s*([A-Z0-9]{4,})"#)
        
        return InsuranceInfo(
            provider: provider ?? "Unknown Provider",
            planName: extractPattern(from: combinedText, pattern: #"(?i)(?:plan|coverage):?\s*(.+)"#) ?? "Standard Plan",
            memberID: memberID ?? "",
            groupNumber: groupNumber ?? "",
            frontImageData: frontImage.jpegData(compressionQuality: 0.7),
            backImageData: backImage?.jpegData(compressionQuality: 0.7)
        )
    }
    
    // MARK: - Helpers
    private func extractField(from text: String, patterns: [String]) -> String? {
        for pattern in patterns {
            if text.localizedCaseInsensitiveContains(pattern) {
                return pattern
            }
        }
        return nil
    }
    
    private func extractPattern(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }
    
    enum OCRError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "Could not process the image" }
    }
}
