import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum ExportFormat {
    case png
    case jpeg(quality: CGFloat)
    case pdf
    
    var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        case .pdf:
            return "pdf"
        }
    }
    
    var mimeType: String {
        switch self {
        case .png:
            return "image/png"
        case .jpeg:
            return "image/jpeg"
        case .pdf:
            return "application/pdf"
        }
    }
    
    var utType: UTType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .pdf:
            return .pdf
        }
    }
}

enum ExportError: LocalizedError {
    case renderingFailed
    case exportFailed
    case invalidFormat
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render the design"
        case .exportFailed:
            return "Failed to export the design"
        case .invalidFormat:
            return "Invalid export format"
        case .saveFailed:
            return "Failed to save the file"
        }
    }
}

protocol Exportable {
    func render(size: CGSize) -> UIView
}

class ExportManager: ObservableObject {
    @Published private(set) var isExporting = false
    @Published private(set) var progress: Double = 0
    @Published var error: ExportError?
    
    private let fileManager: FileManager
    private let exportQueue = DispatchQueue(label: "com.findu.export", qos: .userInitiated)
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func export(_ exportable: Exportable,
                format: ExportFormat,
                size: CGSize,
                filename: String) async throws -> URL {
        isExporting = true
        progress = 0
        defer {
            isExporting = false
            progress = 1
        }
        
        // Create temporary directory if needed
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("exports", isDirectory: true)
        try? fileManager.createDirectory(at: tempDir,
                                      withIntermediateDirectories: true)
        
        // Generate export URL
        let exportURL = tempDir
            .appendingPathComponent(filename)
            .appendingPathExtension(format.fileExtension)
        
        // Remove existing file if needed
        try? fileManager.removeItem(at: exportURL)
        
        return try await withCheckedThrowingContinuation { continuation in
            exportQueue.async {
                do {
                    // Render view
                    let view = exportable.render(size: size)
                    guard let renderer = UIGraphicsImageRenderer(size: size).image(actions: { context in
                        view.drawHierarchy(in: CGRect(origin: .zero, size: size),
                                         afterScreenUpdates: true)
                    }) else {
                        throw ExportError.renderingFailed
                    }
                    
                    DispatchQueue.main.async {
                        self.progress = 0.3
                    }
                    
                    // Convert to required format
                    let data: Data
                    switch format {
                    case .png:
                        guard let pngData = renderer.pngData() else {
                            throw ExportError.exportFailed
                        }
                        data = pngData
                        
                    case .jpeg(let quality):
                        guard let jpegData = renderer.jpegData(compressionQuality: quality) else {
                            throw ExportError.exportFailed
                        }
                        data = jpegData
                        
                    case .pdf:
                        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
                        data = try pdfRenderer.pdfData { context in
                            context.beginPage()
                            view.layer.render(in: context.cgContext)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.progress = 0.6
                    }
                    
                    // Save to file
                    try data.write(to: exportURL)
                    
                    DispatchQueue.main.async {
                        self.progress = 1.0
                        continuation.resume(returning: exportURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.error = error as? ExportError ?? .exportFailed
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func share(_ url: URL,
               from view: UIView,
               completion: @escaping (Bool) -> Void) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            activityVC.completionWithItemsHandler = { _, success, _, _ in
                completion(success)
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = view
                popover.sourceRect = view.bounds
                popover.permittedArrowDirections = [.any]
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#if DEBUG
class PreviewExportable: Exportable {
    func render(size: CGSize) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.backgroundColor = .systemBlue
        return view
    }
}

struct ExportPreview: View {
    @StateObject private var exportManager = ExportManager()
    @State private var isExporting = false
    @State private var exportURL: URL?
    
    var body: some View {
        VStack {
            if exportManager.isExporting {
                ProgressView(value: exportManager.progress) {
                    Text("Exporting...")
                }
                .progressViewStyle(.linear)
            }
            
            Button("Export PNG") {
                Task {
                    do {
                        let url = try await exportManager.export(
                            PreviewExportable(),
                            format: .png,
                            size: CGSize(width: 1024, height: 1024),
                            filename: "preview"
                        )
                        exportURL = url
                        isExporting = true
                    } catch {
                        print("Export failed: \(error)")
                    }
                }
            }
        }
        .alert("Export Error",
               isPresented: .constant(exportManager.error != nil),
               presenting: exportManager.error) { _ in
            Button("OK") {
                exportManager.error = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .sheet(isPresented: $isExporting) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                              context: Context) {}
}
#endif 