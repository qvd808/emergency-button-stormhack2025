import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var hasSetInitialRegion = false

    var body: some View {
        ZStack {
            if let location = locationManager.location {
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .ignoresSafeArea()
                    .onChange(of: locationManager.location) { newLocation in
                        guard let newLocation = newLocation else { return }

                        // Only update once or when user moves >50m
                        if !hasSetInitialRegion ||
                            region.center.distance(to: newLocation.coordinate) > 50 {
                            DispatchQueue.main.async {
                                withAnimation {
                                    region.center = newLocation.coordinate
                                }
                                hasSetInitialRegion = true
                            }
                        }
                    }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Getting your location...")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("📍 Message Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper extension to compute distance between coordinates
extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: latitude, longitude: longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}
