import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var showingScannedPet = false

    var body: some View {
        ZStack {
            if viewModel.cameraPermissionGranted {
                QRCodeScannerRepresentable(
                    onCodeScanned: { scannedValue in
                        // Extract the tag code from the scanned value
                        // It could be a full URL or just the code
                        let code = DeepLinkService.extractTagCode(from: scannedValue)
                        Task {
                            await viewModel.scanQRCode(code)
                            showingScannedPet = true
                        }
                    }
                )
                .ignoresSafeArea()

                // Scanning Overlay
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }

                        Text("Scan QR Code")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text("Point your camera at a pet's QR tag")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.black.opacity(0.7))
                            .background(.ultraThinMaterial)
                            .cornerRadius(28)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)

                    Spacer()
                }
            } else {
                // Camera Permission Required
                VStack(spacing: 24) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray6))
                            .frame(width: 100, height: 100)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.tealAccent)
                    }

                    VStack(spacing: 12) {
                        Text("Camera Access Required")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Please enable camera access in Settings to scan QR codes")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Settings")
                    }
                    .buttonStyle(BrandButtonStyle())
                    .padding(.horizontal, 60)

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingScannedPet) {
            if let result = viewModel.scanResult {
                ScannedPetView(scanResult: result)
            }
        }
        .onAppear {
            viewModel.checkCameraPermission()
        }
    }
}

// UIViewControllerRepresentable for QR Code Scanner
struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onCodeScanned?(stringValue)

            // Stop scanning after first successful scan
            captureSession.stopRunning()
        }
    }
}

struct ScannedPetView: View {
    let scanResult: ScanResponse
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareLocation = false

    private var pet: Pet { scanResult.pet }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Photo
                    AsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Circle()
                                .fill(Color.tealAccent.opacity(0.2))
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.tealAccent)
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Pet Name & Info
                    VStack(spacing: 8) {
                        Text("Hello! I'm \(pet.name)")
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("You've just scanned my tag. Thank you for helping me!")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Pet details row
                        HStack(spacing: 16) {
                            if let breed = pet.breed {
                                Text("**Breed:** \(breed)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let age = pet.age {
                                Text("**Age:** \(age)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let color = pet.color {
                                Text("**Color:** \(color)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                        }
                    }

                    // Share Location Button
                    if pet.qrCode != nil {
                        VStack(spacing: 8) {
                            Button(action: {
                                showingShareLocation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                    Text("Share My Location with Owner")
                                }
                            }
                            .buttonStyle(BrandButtonStyle())
                            .padding(.horizontal, 24)

                            Text("\(pet.name)'s owner will receive an SMS and email with your location")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    // Contact Owner Section
                    if pet.ownerPhone != nil || pet.ownerEmail != nil {
                        VStack(spacing: 16) {
                            Text("Contact Owner")
                                .font(.system(size: 18, weight: .bold))

                            Text("Please let my owner know that you have found me. Tap on the share location button or call them on the phone number below.")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                // Phone (tappable to call)
                                if let phone = pet.ownerPhone {
                                    Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "phone.fill")
                                                .foregroundColor(.tealAccent)
                                            Text("Call: \(phone)")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }

                                // Email (tappable to send email)
                                if let email = pet.ownerEmail {
                                    Link(destination: URL(string: "mailto:\(email)")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(.tealAccent)
                                            Text("Email: \(email)")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Owner Address Section (if publicly visible)
                    if let address = pet.ownerAddress {
                        VStack(spacing: 12) {
                            Text("Owner Location")
                                .font(.system(size: 18, weight: .bold))

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address)
                                        .font(.system(size: 15, weight: .medium))
                                    if let line2 = pet.ownerAddressLine2, !line2.isEmpty {
                                        Text(line2)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    let cityLine = [pet.ownerCity, pet.ownerPostalCode].compactMap { $0 }.joined(separator: ", ")
                                    if !cityLine.isEmpty {
                                        Text(cityLine)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                    if let country = pet.ownerCountry {
                                        Text(country)
                                            .font(.system(size: 14))
                                            .foregroundColor(.mutedText)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }

                    // Medical Information
                    if let medical = pet.medicalInfo, !medical.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.red)
                                Text("Medical Information")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            Text(medical)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // Allergies
                    if let allergies = pet.allergies, !allergies.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Allergies")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            Text(allergies)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // Notes
                    if let notes = pet.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                Text("Notes")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Text(notes)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }

                    // How It Works Card
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How It Works")
                                .font(.system(size: 18, weight: .bold))
                            Text("Help reunite \(pet.name) with their owner safely")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HowItWorksStep(number: "1", title: "Share Your Location", description: "Click the button above to share where you found \(pet.name)")
                            HowItWorksStep(number: "2", title: "Owner Gets Notified", description: "The owner receives an SMS with your location on Google Maps")
                            HowItWorksStep(number: "3", title: "Quick Reunion", description: "Stay near the location so the owner can find you and \(pet.name)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    // Privacy Notice
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.mutedText)
                        Text("Your privacy matters. We'll only share your location with \(pet.name)'s owner with your explicit consent.")
                            .font(.system(size: 12))
                            .foregroundColor(.mutedText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Found \(pet.name)!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandOrange)
                }
            }
            .sheet(isPresented: $showingShareLocation) {
                if let qrCode = pet.qrCode {
                    ShareLocationView(qrCode: qrCode, petName: pet.name)
                }
            }
        }
    }
}

#Preview {
    QRScannerView()
}
