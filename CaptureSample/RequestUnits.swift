//
//  RequestUnits.swift
//  CaptureSample
//
//  Created by ryan on 2024/7/31.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI

class ImageData {
    var index: Int? = nil
    var image: UIImage? = nil
    func setIndex(index: Int){
        self.index = index
    }
    
    func setImage(image: UIImage){
        self.image = image
    }
}
