import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var showingScannedPet = false
    @State private var showOverlay = true
    @State private var isTorchOn = false
    @State private var scannerController: QRScannerViewController?
    @State private var showScanError = false

    var body: some View {
        ZStack {
            if viewModel.cameraPermissionGranted {
                QRCodeScannerRepresentable(
                    onCodeScanned: { scannedValue in
                        // Extract the tag code from the scanned value
                        // It could be a full URL or just the code
                        let code = DeepLinkService.extractTagCode(from: scannedValue)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        Task {
                            await viewModel.scanQRCode(code)
                            if viewModel.scanResult != nil {
                                showingScannedPet = true
                            } else {
                                // Scan failed — show error alert (do NOT auto-resume)
                                showScanError = true
                            }
                        }
                    },
                    onControllerReady: { controller in
                        scannerController = controller
                    }
                )
                .ignoresSafeArea()

                // Scanning Overlay — auto-hides after 5s or on tap
                if showOverlay {
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
                                    .accessibilityLabel(String(localized: "accessibility_qr_scanner"))
                            }

                            Text("scan_qr_code")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("scan_qr_subtitle")
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
                        .onTapGesture {
                            withAnimation { showOverlay = false }
                        }

                        Spacer()
                    }
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation { showOverlay = false }
                        }
                    }
                }

                // Flashlight toggle button — bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { toggleTorch() }) {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(isTorchOn ? Color.brandOrange : Color.black.opacity(0.6))
                                )
                                .accessibilityLabel(isTorchOn ? String(localized: "accessibility_flashlight_off") : String(localized: "accessibility_flashlight_on"))
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 40)
                    }
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
                            .accessibilityLabel(String(localized: "accessibility_camera_required"))
                    }

                    VStack(spacing: 12) {
                        Text("camera_access_required")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)

                        Text("camera_access_message")
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
                        Text("scanner_open_settings")
                    }
                    .buttonStyle(BrandButtonStyle())
                    .padding(.horizontal, 60)

                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingScannedPet, onDismiss: {
            viewModel.reset()
            scannerController?.resumeScanning()
        }) {
            if let result = viewModel.scanResult {
                ScannedPetView(scanResult: result)
            }
        }
        .alert(
            String(localized: "scan_error_title"),
            isPresented: $showScanError
        ) {
            Button(String(localized: "scan_again")) {
                viewModel.reset()
                scannerController?.resumeScanning()
            }
            Button(String(localized: "cancel"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "scan_error_message"))
        }
        .onAppear {
            viewModel.checkCameraPermission()
        }
        .onDisappear {
            // Turn off torch when leaving the scanner
            if isTorchOn { toggleTorch() }
        }
        .secureScreen()
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            isTorchOn.toggle()
            device.torchMode = isTorchOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            #if DEBUG
            print("Failed to toggle torch: \(error)")
            #endif
        }
    }
}

// UIViewControllerRepresentable for QR Code Scanner
struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    var onControllerReady: ((QRScannerViewController) -> Void)?

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        onControllerReady?(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?

    /// Dedicated serial queue for all capture-session operations.
    /// Avoids deadlocks from calling stopRunning on the main thread
    /// and prevents races between start/stop/delegate calls.
    private let sessionQueue = DispatchQueue(label: "pet.senra.scanner.session")

    /// Guard flag so the callback fires exactly once per scan cycle.
    private var isProcessing = false

    private var metadataOutput: AVCaptureMetadataOutput?

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

        let output = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)

            // Deliver metadata on the session queue — never the main thread
            output.setMetadataObjectsDelegate(self, queue: sessionQueue)
            output.metadataObjectTypes = [.qr]
            metadataOutput = output
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func resumeScanning() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.isProcessing = false
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Already on sessionQueue — guard against duplicate callbacks
        guard !isProcessing else { return }

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            isProcessing = true
            captureSession.stopRunning()

            DispatchQueue.main.async { [weak self] in
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self?.onCodeScanned?(stringValue)
            }
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
                    CachedAsyncImage(url: URL(string: pet.photoUrl ?? "")) { image in
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
                                .accessibilityLabel(String(localized: "accessibility_pet_photo"))
                        }
                    }
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Pet Name & Info
                    VStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("hello_pet_name", comment: ""), pet.name))
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("scanned_tag_thanks")
                            .font(.system(size: 15))
                            .foregroundColor(.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // Pet details row
                        HStack(spacing: 16) {
                            if let breed = pet.breed {
                                Text("**\(NSLocalizedString("scanner_breed", comment: "")):** \(breed)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let age = pet.age {
                                Text("**\(NSLocalizedString("scanner_age", comment: "")):** \(age)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let color = pet.color {
                                Text("**\(NSLocalizedString("scanner_color", comment: "")):** \(color)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let sex = pet.sex, !sex.isEmpty {
                                Text("**\(NSLocalizedString("sex_label", comment: "")):** \(sex)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mutedText)
                            }
                            if let neutered = pet.isNeutered {
                                Text("**\(NSLocalizedString("neutered_label", comment: "")):** \(neutered ? NSLocalizedString("yes", comment: "") : NSLocalizedString("no", comment: ""))")
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
                                        .accessibilityLabel(String(localized: "accessibility_share_location"))
                                    Text("share_location_with_owner")
                                }
                            }
                            .buttonStyle(BrandButtonStyle())
                            .padding(.horizontal, 24)

                            Text(String(format: NSLocalizedString("owner_notified_sms_email", comment: ""), pet.name))
                                .font(.system(size: 12))
                                .foregroundColor(.mutedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    // Contact Owner Section
                    if pet.ownerPhone != nil || pet.ownerEmail != nil {
                        VStack(spacing: 16) {
                            Text("contact_owner")
                                .font(.system(size: 18, weight: .bold))

                            Text("contact_owner_plea")
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
                                                .accessibilityLabel(String(localized: "accessibility_call_owner"))
                                            Text(String(format: NSLocalizedString("call_phone", comment: ""), phone))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                                .accessibilityHidden(true)
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
                                                .accessibilityLabel(String(localized: "accessibility_email_owner"))
                                            Text(String(format: NSLocalizedString("email_contact", comment: ""), email))
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mutedText)
                                                .accessibilityHidden(true)
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
                            Text("scanner_owner_location")
                                .font(.system(size: 18, weight: .bold))

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.mutedText)
                                    .frame(width: 20)
                                    .accessibilityLabel(String(localized: "accessibility_owner_address"))

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
                                    .accessibilityLabel(String(localized: "accessibility_medical_info"))
                                Text("scanner_medical_info")
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
                                    .accessibilityLabel(String(localized: "accessibility_allergies"))
                                Text("scanner_allergies")
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
                                    .accessibilityLabel(String(localized: "accessibility_notes"))
                                Text("scanner_notes")
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
                            Text("scanner_how_it_works")
                                .font(.system(size: 18, weight: .bold))
                            Text(String(format: NSLocalizedString("help_reunite_pet", comment: ""), pet.name))
                                .font(.system(size: 14))
                                .foregroundColor(.mutedText)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HowItWorksStep(number: "1", title: NSLocalizedString("step_share_location", comment: ""), description: String(format: NSLocalizedString("scanner_step1_dynamic_desc", comment: ""), pet.name))
                            HowItWorksStep(number: "2", title: NSLocalizedString("step_owner_notified", comment: ""), description: NSLocalizedString("step_owner_notified_desc", comment: ""))
                            HowItWorksStep(number: "3", title: NSLocalizedString("step_quick_reunion", comment: ""), description: String(format: NSLocalizedString("scanner_step3_dynamic_desc", comment: ""), pet.name))
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
                            .accessibilityLabel(String(localized: "accessibility_privacy_notice"))
                        Text(String(format: NSLocalizedString("privacy_notice", comment: ""), pet.name))
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
            .navigationTitle(Text(String(format: NSLocalizedString("found_pet_title", comment: ""), pet.name)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done") {
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
