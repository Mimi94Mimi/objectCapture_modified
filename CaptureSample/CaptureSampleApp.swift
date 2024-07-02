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

//TODO(BLE)
@main
struct CaptureSampleApp: App {
    @StateObject var model: CameraViewModel
    @StateObject var BLE_manager: BLE
    
    init(){
        let BLE_manager = BLE()
        _BLE_manager = StateObject(wrappedValue: BLE_manager)
        _model = StateObject(wrappedValue: CameraViewModel(BLE_manager: BLE_manager))
    }
    
    var body: some Scene {
        
        WindowGroup {
            ContentView(model: model, BLE_manager: BLE_manager)
        }
    }
}
