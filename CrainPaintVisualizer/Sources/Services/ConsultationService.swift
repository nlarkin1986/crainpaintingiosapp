import Foundation

struct ConsultationPackageDetails: Hashable, Sendable {
    let type: ConsultationPackageType
    let name: String
    let subtitle: String
    let price: Decimal
    let turnaround: String
    let features: [String]
}

protocol ConsultationService {
    func packageDetails(for type: ConsultationPackageType) -> ConsultationPackageDetails
    func makeFlowState(from visualization: Visualization?) -> ConsultationFlowState
}

struct DefaultConsultationService: ConsultationService {
    func packageDetails(for type: ConsultationPackageType) -> ConsultationPackageDetails {
        switch type {
        case .quickReview:
            return ConsultationPackageDetails(
                type: type,
                name: "Quick Color Review",
                subtitle: "Fast expert feedback for a single room.",
                price: 49,
                turnaround: "24-48 hours",
                features: [
                    "2-3 expert color directions",
                    "Lighting-aware written rationale",
                    "Delivered by email and web"
                ]
            )
        case .videoConsultation:
            return ConsultationPackageDetails(
                type: type,
                name: "Detailed Color Analysis",
                subtitle: "In-depth expert review with a recorded walkthrough.",
                price: 149,
                turnaround: "2-3 business days",
                features: [
                    "4-5 expert recommendations",
                    "Recorded walkthrough from Curt",
                    "Lighting and time-of-day analysis"
                ]
            )
        case .wholeHome:
            return ConsultationPackageDetails(
                type: type,
                name: "Whole Home Color Plan",
                subtitle: "A complete color strategy for multiple connected spaces.",
                price: 399,
                turnaround: "5-7 business days",
                features: [
                    "Whole-home palette strategy",
                    "Surface prep and finish guidance",
                    "Downloadable PDF report"
                ]
            )
        }
    }

    func makeFlowState(from visualization: Visualization?) -> ConsultationFlowState {
        ConsultationFlowState(
            sourceVisualizationID: visualization?.id,
            sourceColor: visualization?.asPaintColor,
            sourceRoomName: visualization?.roomName
        )
    }
}
