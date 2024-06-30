/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view.
*/

import SwiftUI

/// This is the root view for the app.
struct ContentView: View {
    //TODO(BLE)
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE

    var body: some View {
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
