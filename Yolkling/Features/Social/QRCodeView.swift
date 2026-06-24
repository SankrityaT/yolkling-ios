import SwiftUI
import CoreImage.CIFilterBuiltins

/// A pure SwiftUI view that renders a QR code for `text` using CoreImage.
/// Interpolation is disabled so the code stays crisp at any size.
struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = makeQR(text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
        } else {
            // Fallback: placeholder square if generation fails
            RoundedRectangle(cornerRadius: 8)
                .fill(YolkColor.shell2)
                .frame(width: 220, height: 220)
                .overlay(
                    Text("QR unavailable")
                        .font(YolkType.bodySmall)
                        .foregroundStyle(YolkColor.muted)
                )
        }
    }

    // MARK: - Private

    private func makeQR(_ string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        // Scale up to a crisp 440x440 pt (2x for rendering) using nearest-neighbor
        let scale = 440.0 / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#if DEBUG
#Preview {
    ZStack {
        YolkColor.shell.ignoresSafeArea()
        QRCodeView(text: "https://yolkling.com/add/YOLK-TEST")
            .padding(YolkSpace.lg)
    }
}
#endif
