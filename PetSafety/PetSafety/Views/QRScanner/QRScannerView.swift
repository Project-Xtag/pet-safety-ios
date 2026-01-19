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

                    VStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Scan QR Code")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Point your camera at a pet's QR tag")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding()

                    Spacer()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Please enable camera access in Settings to scan QR codes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                }
            }
        }
        .navigationTitle("QR Scanner")
        .navigationBarTitleDisplayMode(.inline)
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
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())

                    // Pet Name
                    Text("Hello! I'm \(scanResult.pet.name)")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("You've just scanned my tag. Thank you for helping me!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("\(scanResult.pet.species) • \(scanResult.pet.breed ?? "Unknown")")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    // Scan notification
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("My owner has been automatically notified that you found me")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Share Location Button
                    if scanResult.pet.qrCode != nil {
                        Button(action: {
                            showingShareLocation = true
                        }) {
                            Label("Share My Location with Owner", systemImage: "location.fill")
                                .font(.headline)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)

                        Text("\(scanResult.pet.name)'s owner will receive an SMS and email with your location to help reunite them quickly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Contact Owner Section (only if phone or email are public)
                    if scanResult.pet.ownerPhone != nil || scanResult.pet.ownerEmail != nil {
                        VStack(spacing: 12) {
                            Text("Contact Owner")
                                .font(.headline)

                            Text("Please let my owner know that you have found me. Tap on the share location button or call them on the phone number below.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                if let phone = scanResult.pet.ownerPhone {
                                    Link(destination: URL(string: "tel:\(phone)")!) {
                                        Label("Call: \(phone)", systemImage: "phone.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .foregroundColor(.primary)
                                            .cornerRadius(10)
                                    }
                                }

                                if let email = scanResult.pet.ownerEmail {
                                    Link(destination: URL(string: "mailto:\(email)")!) {
                                        Label("Email: \(email)", systemImage: "envelope.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .foregroundColor(.primary)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        .padding()
                    }

                    // Pet Info
                    if let color = scanResult.pet.color {
                        InfoCard(title: "Color", value: color, icon: "paintpalette.fill")
                            .padding(.horizontal)
                    }

                    if let medical = scanResult.pet.medicalInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Medical Information", systemImage: "cross.case.fill")
                                .font(.headline)
                                .foregroundColor(.red)

                            Text(medical)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Found \(scanResult.pet.name)!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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

#Preview {
    QRScannerView()
}
