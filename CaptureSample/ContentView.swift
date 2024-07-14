/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "ContentView")

/// This is the root view for the app.
struct ContentView: View {
    //TODO(BLE)
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    @State private var hasCapturedOnce: Bool = false
    
    func shutterManager(){
        DispatchQueue.main.async {
            if(BLE_manager.charValue?.shouldTakePhoto == "true" && !hasCapturedOnce){
                hasCapturedOnce = true
                model.captureFromShutterManager()
            }
            else if(BLE_manager.charValue?.shouldTakePhoto == "false"){
                hasCapturedOnce = false
            }
        }
    }
    
    var body: some View {
        let _ = shutterManager()
        ZStack {
            // Make the entire background black.
            Color.black.edgesIgnoringSafeArea(.all)
            CameraView(model: model, BLE_manager: BLE_manager)
        }
        // Force dark mode so the photos pop.
        .environment(\.colorScheme, .dark)
    }
    
}
