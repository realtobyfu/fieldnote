//
//  CaptureMode.swift
//  Fieldnote
//
//  Represents how a capture session was initiated
//

import UIKit

enum CaptureMode {
    /// Identification result plus, when available, the reranked alternative
    /// candidates so the review sheet can offer "did you mean…?" choices instead
    /// of presenting the top match as a certainty.
    /// See LocaleAwareCatalogImplementationPlan.md (B4).
    case mlIdentification(
        result: PlantIdentificationResult,
        image: UIImage,
        alternatives: [RankedCandidate] = []
    )
    case manualEntry

    var hasPrefilledData: Bool {
        switch self {
        case .mlIdentification: return true
        case .manualEntry: return false
        }
    }

    var image: UIImage? {
        switch self {
        case .mlIdentification(_, let image, _): return image
        case .manualEntry: return nil
        }
    }

    var identificationResult: PlantIdentificationResult? {
        switch self {
        case .mlIdentification(let result, _, _): return result
        case .manualEntry: return nil
        }
    }

    /// Reranked alternatives (excluding the chosen top result), if any.
    var alternatives: [RankedCandidate] {
        switch self {
        case .mlIdentification(_, _, let alternatives): return alternatives
        case .manualEntry: return []
        }
    }
}
