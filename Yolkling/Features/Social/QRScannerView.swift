import SwiftUI
import AVFoundation

// MARK: - Public representable

/// A UIViewControllerRepresentable that wraps AVFoundation QR scanning.
/// `onScan` is called exactly once (on the main queue) with the detected code
/// (either a raw "YOLK-XXXX" code or a "https://yolkling.com/add/<code>" URL
/// parsed down to just the code component).
///
/// Swift 6 notes:
/// - AVCaptureSession and its related types are NOT Sendable; all capture work
///   stays on a dedicated serial background DispatchQueue.
/// - Coordinator is @unchecked Sendable so it can be referenced across isolation
///   boundaries without compiler errors.
struct QRScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onScan = onScan
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Coordinator (unused directly; kept for protocol conformance pattern)

    final class Coordinator: NSObject, @unchecked Sendable {}
}

// MARK: - ScannerViewController

/// UIViewController that owns the AVCaptureSession.
/// All capture setup and teardown runs on `captureQueue`, never on MainActor.
final class ScannerViewController: UIViewController {
    var onScan: ((String) -> Void)?

    private let captureQueue = DispatchQueue(label: "com.Sankritya.Yolkling.scannerQueue")
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// Guards against firing onScan more than once per presentation.
    private var didScan = false

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Request camera access, then set up on success.
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            if granted {
                self.captureQueue.async { self.setupSession() }
            } else {
                DispatchQueue.main.async { self.showDeniedMessage() }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureQueue.async { [weak self] in
            guard let s = self?.session, !s.isRunning else { return }
            s.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureQueue.async { [weak self] in
            self?.session?.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Private

    private func setupSession() {
        let newSession = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              newSession.canAddInput(input) else {
            DispatchQueue.main.async { [weak self] in self?.showSetupError() }
            return
        }

        newSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard newSession.canAddOutput(output) else {
            DispatchQueue.main.async { [weak self] in self?.showSetupError() }
            return
        }
        newSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: captureQueue)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: newSession)
        preview.videoGravity = .resizeAspectFill

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            preview.frame = self.view.bounds
            self.view.layer.insertSublayer(preview, at: 0)
            self.previewLayer = preview
        }

        newSession.startRunning()
        session = newSession
    }

    private func showDeniedMessage() {
        let label = UILabel()
        label.text = "camera access is needed to scan a friend's code. you can enable it in Settings."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func showSetupError() {
        let label = UILabel()
        label.text = "could not start the camera. try closing and reopening the app."
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    // Called on captureQueue.
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !didScan,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let raw = obj.stringValue else { return }

        let code = extracted(from: raw)
        guard !code.isEmpty else { return }

        didScan = true
        session?.stopRunning()

        let cb = onScan
        DispatchQueue.main.async {
            cb?(code)
        }
    }

    /// Extract a YOLK-XXXX code from either a raw code or a deep-link URL.
    private func extracted(from raw: String) -> String {
        if raw.hasPrefix("YOLK-") {
            return raw
        }
        // Attempt URL parse: https://yolkling.com/add/<code>
        if let url = URL(string: raw),
           let host = url.host,
           host.contains("yolkling.com"),
           url.pathComponents.count >= 3,
           url.pathComponents[1] == "add" {
            let code = url.pathComponents[2]
            if code.hasPrefix("YOLK-") { return code }
        }
        return ""
    }
}
