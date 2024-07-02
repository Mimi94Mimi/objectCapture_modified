/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "CameraViewModel")

/// This is the root view for the app.
struct ContentView: View {
    //TODO(BLE)
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    var connectedCounter = Timer()
//    @State private var lastShouldTakePhoto: Bool = false
//    @State private var calls: Int = 0
    
    
    
    func shutterManager(){
        if(BLE_manager.charValue?.shouldTakePhoto == "true" && model.lastShouldTakePhoto == false){
            model.lastShouldTakePhoto = true
            model.logCaptureTimeInterval()
            model.capturePhotoAndMetadata()
            model.calls += 1
            model.photoLeft -= 1
            if model.BLEtriggerEveryTimer != nil {
                if model.photoLeft <= 0 {
                    model.BLEtriggerEveryTimer?.stop()
                    return
                } else if !model.BLEtriggerEveryTimer!.isRunning {
                    model.BLEtriggerEveryTimer?.start()
                    logger.log("start BLEtriggerEveryTimer")
                }
            }
            logger.log("call capturePhotoAndMetadata: \(model.calls)")
        }
        else if(BLE_manager.charValue?.shouldTakePhoto == "false" && model.lastShouldTakePhoto == true){
            model.lastShouldTakePhoto = false
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

//struct ContentView_Previews: PreviewProvider {
//    @StateObject private static var model = CameraViewModel()
//    @StateObject private static var BLE = BLE()
//    static var previews: some View {
//        ContentView(model: model, BLE_manager: BLE_manager)
//    }
//}
