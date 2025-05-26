
import SwiftUI
import MapKit

enum TransportMode: String, CaseIterable, Hashable {
    case driving = "Driving"
    case walking = "Walking"
    case transit = "Transit"
    
    var mkType: MKDirectionsTransportType {
        switch self {
        case .driving: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPOI: POI? = nil
    @State private var mapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 43.65107, longitude: -79.347015),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedTransport: TransportMode = .driving
    @State private var travelTime: String? = nil
    
    let samplePOIs = [
        POI(name: "CN Tower", description: "Tallest structure in Toronto", coordinate: CLLocationCoordinate2D(latitude: 43.6426, longitude: -79.3871), category: "Landmark"),
        POI(name: "High Park", description: "Huge park with trails and a zoo", coordinate: CLLocationCoordinate2D(latitude: 43.6465, longitude: -79.4637), category: "Park"),
        POI(name: "Union Station", description: "Main train hub downtown", coordinate: CLLocationCoordinate2D(latitude: 43.6452, longitude: -79.3806), category: "Transit"),
        POI(name: "St. Lawrence Market", description: "Famous food and goods market", coordinate: CLLocationCoordinate2D(latitude: 43.6487, longitude: -79.3716), category: "Shopping"),
        POI(name: "Toronto Zoo", description: "Huge zoo with animals from all over", coordinate: CLLocationCoordinate2D(latitude: 43.8177, longitude: -79.1859), category: "Zoo"),
        POI(name: "City Hall", description: "Historic Toronto City Hall building", coordinate: CLLocationCoordinate2D(latitude: 43.6525, longitude: -79.3841), category: "Landmark"),
        POI(name: "Exhibition Palace", description: "Event and fairground complex", coordinate: CLLocationCoordinate2D(latitude: 43.6332, longitude: -79.4142), category: "Park"),
        POI(name: "Toronto Metropolitan University", description: "Major downtown university campus, formerly Ryerson", coordinate: CLLocationCoordinate2D(latitude: 43.6577, longitude: -79.3788),category: "Landmark"),
        POI(name: "Scotiabank Arena", description: "Home of the Raptors and Maple Leafs", coordinate: CLLocationCoordinate2D(latitude: 43.6435, longitude: -79.3791), category: "Landmark"),
        POI(name: "Hockey Hall of Fame", description: "Museum dedicated to the history of hockey", coordinate: CLLocationCoordinate2D(latitude: 43.6473, longitude: -79.3777), category: "Landmark"),
        POI(name: "Metro Toronto Convention Centre",description: "Large event venue near CN Tower and Union",coordinate: CLLocationCoordinate2D(latitude: 43.6430, longitude: -79.3860),category: "Landmark"),
        POI(name: "Ripley's Aquarium",description: "Family-friendly aquarium near CN Tower",coordinate: CLLocationCoordinate2D(latitude: 43.6424, longitude: -79.3860),category: "Landmark")
    ]
    
    var categories: [String] {
        ["All"] + Set(samplePOIs.map { $0.category }).sorted()
    }
    
    var filteredPOIs: [POI] {
        samplePOIs.filter { poi in
            (selectedCategory == "All" || poi.category == selectedCategory) &&
            (searchText.isEmpty || poi.name.lowercased().contains(searchText.lowercased()))
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if let location = locationManager.lastLocation {
                Map(position: $mapCameraPosition, selection: $selectedPOI) {
                    UserAnnotation()
                    ForEach(filteredPOIs) { poi in
                        Marker(poi.name, coordinate: poi.coordinate)
                            .tint(.red)
                            .tag(poi)
                    }
                }
                .onAppear {
                    mapCameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
                .ignoresSafeArea()
            } else {
                Text("Waiting for location or permission denied")
                    .padding()
            }
            
            VStack(spacing: 8) {
                HStack {
                    TextField("Search POIs...", text: $searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                Spacer()
            }
            
            if let poi = selectedPOI {
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        HStack {
                            Text(poi.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button {
                                selectedPOI = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            Text("Category: \(poi.category)")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        Text(poi.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let userLocation = locationManager.lastLocation {
                            let poiLocation = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
                            let distanceInMeters = userLocation.distance(from: poiLocation)
                            let distanceInKM = distanceInMeters / 1000.0
                            
                            HStack {
                                Text(String(format: "Distance: %.2f km", distanceInKM))
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        
                        Picker("Mode", selection: $selectedTransport) {
                            ForEach(TransportMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if let travelTime = travelTime {
                            HStack {
                                Text("ETA: \(travelTime)")
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        
                        Button {
                            mapCameraPosition = .region(
                                MKCoordinateRegion(
                                    center: poi.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            )
                            calculateETA(to: poi)
                        } label: {
                            Text("Center on Map & Get ETA")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding()
                }
                .transition(.move(edge: .bottom))
            }
        }
        .onChange(of: selectedPOI) { poi in
            if let poi = poi {
                calculateETA(to: poi)
            }
        }
        .onChange(of: selectedTransport) { _ in
            if let poi = selectedPOI {
                calculateETA(to: poi)
            }
        }
    }
    
    func calculateETA(to poi: POI) {
        guard let userLocation = locationManager.lastLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: poi.coordinate))
        request.transportType = selectedTransport.mkType
        
        let directions = MKDirections(request: request)
        directions.calculateETA { response, error in
            if let eta = response?.expectedTravelTime {
                let minutes = eta / 60
                DispatchQueue.main.async {
                    self.travelTime = String(format: "%.0f min", minutes)
                }
            } else {
                DispatchQueue.main.async {
                    self.travelTime = "N/A"
                }
            }
        }
    }
}
