import UIKit

protocol Exportable {
    func render(size: CGSize) -> UIView
}

extension Exportable {
    func exportAsImage(size: CGSize) -> UIImage? {
        let view = render(size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func exportAsPDF(size: CGSize) -> Data? {
        let view = render(size: size)
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: size), nil)
        defer { UIGraphicsEndPDFContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        UIGraphicsBeginPDFPage()
        view.layer.render(in: context)
        
        return pdfData as Data
    }
} 