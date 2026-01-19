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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Photo
                    AsyncImage(url: URL(string: scanResult.pet.photoUrl ?? "")) { image in
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

                    // Pet Name
                    VStack(spacing: 8) {
                        Text("Hello! I'm \(scanResult.pet.name)")
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("You've just scanned my tag. Thank you for helping me!")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Text("\(scanResult.pet.species) \(scanResult.pet.breed.map { "• \($0)" } ?? "")")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                    }

                    // Scan notification
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("My owner has been automatically notified")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)

                    // Share Location Button
                    if scanResult.pet.qrCode != nil {
                        VStack(spacing: 12) {
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

                            Text("\(scanResult.pet.name)'s owner will receive an SMS and email with your location")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    // Contact Owner Section
                    if scanResult.pet.ownerPhone != nil || scanResult.pet.ownerEmail != nil {
                        VStack(spacing: 16) {
                            Text("Contact Owner")
                                .font(.system(size: 18, weight: .bold))

                            Text("Please let my owner know that you have found me")
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                if let phone = scanResult.pet.ownerPhone {
                                    Link(destination: URL(string: "tel:\(phone)")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "phone.fill")
                                                .foregroundColor(.tealAccent)
                                            Text("Call: \(phone)")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }

                                if let email = scanResult.pet.ownerEmail {
                                    Link(destination: URL(string: "mailto:\(email)")!) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(.tealAccent)
                                            Text("Email: \(email)")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(14)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Pet Info Cards
                    if let color = scanResult.pet.color {
                        ScannedPetInfoCard(title: "Color", value: color, icon: "paintpalette.fill")
                            .padding(.horizontal, 24)
                    }

                    if let medical = scanResult.pet.medicalInfo {
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
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Found \(scanResult.pet.name)!")
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
                if let qrCode = scanResult.pet.qrCode {
                    ShareLocationView(qrCode: qrCode, petName: scanResult.pet.name)
                }
            }
        }
    }
}

// MARK: - Scanned Pet Info Card
struct ScannedPetInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.tealAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.mutedText)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(14)
    }
}

#Preview {
    QRScannerView()
}
