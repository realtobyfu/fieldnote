//
//  CaptureMode.swift
//  Fieldnote
//
//  Represents how a capture session was initiated
//

import UIKit

enum CaptureMode {
    case mlIdentification(result: PlantIdentificationResult, image: UIImage)
    case manualEntry

    var hasPrefilledData: Bool {
        switch self {
        case .mlIdentification: return true
        case .manualEntry: return false
        }
    }

    var image: UIImage? {
        switch self {
        case .mlIdentification(_, let image): return image
        case .manualEntry: return nil
        }
    }

    var identificationResult: PlantIdentificationResult? {
        switch self {
        case .mlIdentification(let result, _): return result
        case .manualEntry: return nil
        }
    }
}
