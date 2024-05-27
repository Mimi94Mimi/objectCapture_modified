class BLEViewModel: ObservableObject {
    var BLE_manager: BLE? {
        return captureFolderState?.captureDir
    }

    @Published
}