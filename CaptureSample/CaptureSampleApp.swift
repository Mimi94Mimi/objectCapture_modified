/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom app subclass.
*/

import SwiftUI

//@main
//struct CaptureSampleApp: App {
//    @StateObject var model = CameraViewModel()
//    @StateObject var BLEmodel = BLEViewModel()
//
//    var body: some Scene {
//        WindowGroup {
//            //ContentView(model: model)
//            BLEOptionsView(model: BLEmodel)
//        }
//    }
//}

@main
struct CaptureSampleApp: App {
    @StateObject var BLE_manager = BLE()
    
    
    var body: some Scene {
        WindowGroup {
            //ContentView(model: model)
            BLEOptionsView(BLE_manager)
        }
    }
}
