import Foundation
import UIKit

/**
Responsible for filtering images.

@author Julian Builes
*/
class ImageFilterOperation: ImageOperation {
  
  override func main() {
    
    if self.cancelled {
      return
    }
    
    if photoRecord.state != .Downloaded {
      return
    }
    
    if let filteredImage = applySepiaFilter(photoRecord.image!) {
      photoRecord.image = filteredImage
      photoRecord.state = .Filtered
    }
  }
  
  func applySepiaFilter(image: UIImage) -> UIImage? {
    
    let inputImage = CIImage(data: UIImagePNGRepresentation(image))
    
    if self.cancelled {
      return nil
    }
    
    let context = CIContext(options: nil)
    let filter = CIFilter(name: "CISepiaTone")
    filter.setValue(inputImage, forKey: kCIInputImageKey)
    filter.setValue(0.8, forKey: "inputIntensity")
    let outputImage = filter.outputImage
    
    if self.cancelled {
      return nil
    }
    
    let outImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
    return UIImage(CGImage: outImage)
  }
}