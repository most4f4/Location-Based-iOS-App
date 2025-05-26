import SwiftUI

struct POIDetailView: View {
    let poi: POI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poi.name)
                .font(.title2).bold()
            Text(poi.description)
                .font(.body)
            Text("Category: \(poi.category)")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding()
    }
}
#Preview {
    POIDetailView(poi: .init(name: "Test", description: "Test", coordinate: .init(latitude: 0, longitude: 0), category: "Test"))
}