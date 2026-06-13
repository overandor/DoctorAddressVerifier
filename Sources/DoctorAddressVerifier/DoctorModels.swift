import Foundation

struct Doctor: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let city: String
    let state: String
    let zip: String
    let specialty: String
}

enum VerificationConfidence: String, Codable {
    case high, medium, low, unknown
}

enum VerificationAction: String, Codable {
    case accepted, rejected, needsReview
}

struct VerificationResult: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let originalAddress: String
    let standardizedAddress: String
    let standardizedCity: String
    let standardizedState: String
    let standardizedZip: String
    let isValid: Bool
    let confidence: VerificationConfidence
    let action: VerificationAction
    let territory: String
    let evidence: String?
    let notes: String
    let sources: [String]
    let npi: String?
}

struct CrawlEvent: Codable {
    let type: String
    let doctor: String?
    let message: String?
    let progress: CrawlProgress?
    let total: Int?
    let pending: Int?
    let done: Int?
    let count: Int?
    let result: EnrichmentResult?
}

struct EnrichmentResult: Codable {
    let name: String
    let sources: [String]?
    let npi: String?
    let standardizedAddress: String?
    let standardizedCity: String?
    let standardizedState: String?
    let standardizedZip: String?
    let confidence: String?
    let action: String?
    let evidence: String?
    let notes: String?
}

struct CrawlProgress: Codable {
    let done: Int
    let total: Int
}
