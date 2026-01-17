import SwiftUI
import CoreLocation

struct ShareLocationView: View {
    let qrCode: String
    let petName: String

    @StateObject private var locationManager = LocationManager()
    @State private var isSharing = false
    @State private var shared = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Share Your Location")
                    .font(.title2)
                    .bold()

                Text("The owner will receive your current location via SMS and email")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                if let location = locationManager.location {
                    VStack(spacing: 8) {
                        Text("Current Location")
                            .font(.headline)
                        Text("Lat: \(location.latitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Lng: \(location.longitude, specifier: "%.6f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Getting your location...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if shared {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Location Shared!")
                            .font(.headline)
                        Text("The owner has been notified")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    Button(action: shareLocation) {
                        if isSharing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Sharing...")
                                    .foregroundColor(.white)
                            }
                        } else {
                            Label("Share Location", systemImage: "location.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(locationManager.location == nil || isSharing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(locationManager.location == nil || isSharing)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Found \(petName)!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
    }

    func shareLocation() {
        guard let location = locationManager.location else {
            errorMessage = "Location not available. Please enable location services."
            return
        }

        isSharing = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.shareLocation(
                    qrCode: qrCode,
                    latitude: location.latitude,
                    longitude: location.longitude
                )

                await MainActor.run {
                    shared = true
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                    isSharing = false
                }
            } catch {
                await MainActor.run {
                    print("Error sharing location: \(error)")
                    errorMessage = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }
}

#Preview {
    ShareLocationView(qrCode: "TEST123", petName: "Buddy")
}
