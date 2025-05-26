import SwiftUI
import MapKit

struct POI: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let category: String

    static func ==(lhs: POI, rhs: POI) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
