import CoreBluetooth
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "BLEService")

struct CharValue {
    var mode: String = "fixed_angle"
    var numOfPhoto: Int = 5
    var timeInterval: Double = 1.5
    var angle: Int = 3
    var cameraState: String = "idle"
    var shouldTakePhoto: String = "false"
    var connected: String = "disconnected"
}
    
struct LastCharValue {
    var cameraState: String? = "idle"
    var shouldTakePhoto: String? = "false"
}

struct Characteristics {
    var modeChar: CBCharacteristic?
    var numOfPhotoChar: CBCharacteristic?
    var timeIntervalChar: CBCharacteristic?
    var angleChar: CBCharacteristic?
    var cameraStateChar: CBCharacteristic?
    var shouldTakePhotoChar: CBCharacteristic?
    var connectedChar: CBCharacteristic?
}

struct CBUUIDs {
    static let BLEService_UUID =        CBUUID(string: "187F0000-44AD-4F56-BEE4-23B6CAC3FE46")
    static let mode_UUID =              CBUUID(string: "187F0001-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Write)
    static let numOfPhoto_UUID =        CBUUID(string: "187F0002-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Write)
    static let timeInterval_UUID =      CBUUID(string: "187F0003-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Write)
    static let angle_UUID =             CBUUID(string: "187F0004-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Write)
    static let cameraState_UUID =       CBUUID(string: "187F0005-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Read/Notify/Write)
    static let shouldTakePhoto_UUID =   CBUUID(string: "187F0006-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Read/Notify/Write)
    static let connected_UUID =         CBUUID(string: "187F0007-44AD-4F56-BEE4-23B6CAC3FE46")// (Property = Read/Write)
    static let characteristic_UUIDs = [
        mode_UUID,
        numOfPhoto_UUID,
        timeInterval_UUID,
        angle_UUID,
        cameraState_UUID,
        shouldTakePhoto_UUID,
        connected_UUID
    ]
}

class BLE: NSObject, ObservableObject {
    
    @Published var charValue: CharValue?
    @Published var lastCharValue: LastCharValue?
    @Published var RPIcharacteristics: Characteristics?

    @Published var isWaiting: Bool = true
    @Published var isShooting: Bool = false
    @Published var buttonText: String = "START"
    @Published var current_RSSI: Float = 0
    //temp
    @Published var shutter: Bool = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        charValue = CharValue()
        lastCharValue = LastCharValue()
        RPIcharacteristics = Characteristics()
        disconnectFromDevice()
    }

    private var centralManager: CBCentralManager!
    private var RPIperipheralManager: CBPeripheralManager?
    private var RPIperipheral: CBPeripheral?
    private var cameraService: CBService?

    

    private var nanosec_shooting_TI: UInt64? = 0
    private var connectedCounterValue: Int = 0
    private var scanTimer: Timer?
    private var RSSIbound: Float = -70
    
    //find peripheral
    private func connectToDevice() -> Void {
        centralManager?.connect(RPIperipheral!, options: nil)
    }

    private func disconnectFromDevice() -> Void {
        if RPIperipheral != nil {
            centralManager?.cancelPeripheralConnection(RPIperipheral!)
        }
    }

    private func startScanning() -> Void {
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
        scanTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }

    private func stopScanning() -> Void {
        centralManager?.stopScan()
    }

    private func delayedConnection() -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            //Once connected, move to new view controller to manager incoming and outgoing data
            self.connectionEstablished()
        })
    }

    //after connection
    private var connectedCounter: Timer?

    private func connectionEstablished() {
        
        writeOutgoingValue(data: "0", txChar: RPIcharacteristics?.connectedChar)
        isShooting = false
        isWaiting = true
        connectedCounter = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
            self.sendCounterValue()
        }
    }

    private func sendCounterValue() {
        if (current_RSSI > RSSIbound) {
            connectedCounterValue += 1
            isWaiting = false
        }
        else {
            if (isWaiting == false){
                isWaiting = true
            }
        }
        writeOutgoingValue(data: String("\(connectedCounterValue)"), txChar: RPIcharacteristics?.connectedChar)
    }

    private func handleCameraState(value: String) -> Void{
       if (value != lastCharValue?.cameraState){
            print("camera state changes: \(value)")
            lastCharValue?.cameraState = value
            charValue?.cameraState = value
            if (value == "idle") {
                isShooting = false
                nanosec_shooting_TI = 0
            }
            else if (lastCharValue?.cameraState == "shooting") {
            }
        }
    }

    private func handleShouldTakePhoto(value: String) -> Void{
        //logger.log("call handle should take photo")
        if(value != lastCharValue?.shouldTakePhoto){
            lastCharValue?.shouldTakePhoto = value
            if (lastCharValue?.shouldTakePhoto == "false") {
                charValue?.shouldTakePhoto = "false"
            }
            else if (lastCharValue?.shouldTakePhoto == "true") {
                writeOutgoingValue(data: "false" , txChar: RPIcharacteristics?.shouldTakePhotoChar)
                charValue?.shouldTakePhoto = "true"
            }
        }
    }

    private func takePhoto(){
        logger.log("take a photo")
        self.shutter = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.shutter = false
        }
        if (charValue?.mode == "fixed_time_interval") {
            if(nanosec_shooting_TI != 0){
                let time_after = Double(DispatchTime.now().uptimeNanoseconds - nanosec_shooting_TI!) / Double(1000000000)
                nanosec_shooting_TI = DispatchTime.now().uptimeNanoseconds
                print("\(time_after)s after last shot")
            }
            else{
                nanosec_shooting_TI = DispatchTime.now().uptimeNanoseconds
            }
        }
    }

    func writeOutgoingValue(data: String, txChar: CBCharacteristic?){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        //change the "data" to valueString
        if RPIperipheral != nil {
            if let txCharacteristic = txChar {
                RPIperipheral?.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    // View objects actions
    func modeCtrlAction(_ text: String) {
        charValue?.mode = text
        print("mode -> \(String(text))")
        writeOutgoingValue(data: text, txChar: RPIcharacteristics?.modeChar)
    }
    
    func numOfPhotoTFAction(_ text: String) -> String {
        guard let input = Int(text) else {
            return "Value error"
        }
        if input < 1 || input > 200 {
            return "Invalid value"
        }
        charValue?.numOfPhoto = input
        print("numofphoto -> \(String(input))")
        writeOutgoingValue(data: text, txChar: RPIcharacteristics?.numOfPhotoChar)
        return "Success"
    }

    func angleTFAction(_ text: String) -> String {
        guard let input = Int(text) else {
            return "Value error"
        }
        if input < 1 || input > 45 {
            return "Invalid value"
        }
        charValue?.angle = input
        print("angle -> \(String(input))")
        writeOutgoingValue(data: text, txChar: RPIcharacteristics?.angleChar)
        return "Success"
    }
    
    func timeIntervalTFAction(_ text: String) -> String {
        guard let input = Double(text) else {
            return "Value error"
        }
        if input < 0.2 || input > 20.0 {
            return "Invalid value"
        }
        charValue?.timeInterval = input
        print("angle -> \(String(format: "%.2f", input))")
        writeOutgoingValue(data: text, txChar: RPIcharacteristics?.timeIntervalChar)
        return "Success"
    }
    
    func cameraButtonAction() {
        print("cb action")
        if (charValue?.cameraState == "idle") {
            writeOutgoingValue(data: "shooting", txChar: RPIcharacteristics?.cameraStateChar)
            charValue?.cameraState = "shooting"
        }
        else if (charValue?.cameraState == "shooting") {
            //BLE_manager.writeOutgoingValue(data: "idle", txChar: BLE_manager.RPIcharacteristics?.cameraStateChar)
            charValue?.cameraState = "idle"
        }
    }

    private func didcloseAPP() {
        writeOutgoingValue(data: "disconnected" , txChar: RPIcharacteristics?.connectedChar)
    }

    deinit {
        print("deinit")
        didcloseAPP()
    }
}

extension BLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                print("Is Powered Off.")
                //BLEViewModel.bluetoothAlert();
            case .poweredOn:
                print("Is Powered On.")
                startScanning()
            case .unsupported:
                print("Is Unsupported.")
            case .unauthorized:
            print("Is Unauthorized.")
            case .unknown:
                print("Unknown")
            case .resetting:
                print("Resetting")
            @unknown default:
                print("Error")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "raspberrypi" {
            print("Function: \(#function),Line: \(#line)")

            RPIperipheral = peripheral
            RPIperipheral?.delegate = self

            print("Peripheral Discovered: \(peripheral)")
            print ("Advertisement Data : \(advertisementData)")
            connectToDevice()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        RPIperipheral?.discoverServices([CBUUIDs.BLEService_UUID])
        logger.log("start reading RSSI")
        peripheral.readRSSI()
    }

}

extension BLE: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        cameraService = services[0]
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        guard let characteristics = service.characteristics else {
            return
        }

        print("Found \(characteristics.count) characteristics.")

        for characteristic in characteristics {
            if CBUUIDs.characteristic_UUIDs.contains(characteristic.uuid) {
                print("Characteristic: \(characteristic.uuid.uuidString) has been found.")
                switch characteristic.uuid {
                    case CBUUIDs.mode_UUID:
                    RPIcharacteristics?.modeChar = characteristic
                    break
                    case CBUUIDs.numOfPhoto_UUID:
                    RPIcharacteristics?.numOfPhotoChar = characteristic
                    break
                    case CBUUIDs.timeInterval_UUID:
                    RPIcharacteristics?.timeIntervalChar = characteristic
                    break
                    case CBUUIDs.angle_UUID:
                    RPIcharacteristics?.angleChar = characteristic
                    break
                    case CBUUIDs.cameraState_UUID:
                    RPIcharacteristics?.cameraStateChar = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    break
                    case CBUUIDs.shouldTakePhoto_UUID:
                    RPIcharacteristics?.shouldTakePhotoChar = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    break
                    case CBUUIDs.connected_UUID:
                    RPIcharacteristics?.connectedChar = characteristic
                    break
                    default:
                    break
                }
            }
        }
        delayedConnection()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        var characteristicASCIIValue = NSString()

        guard characteristic == RPIcharacteristics?.cameraStateChar || characteristic == RPIcharacteristics?.shouldTakePhotoChar,
        let charValue = characteristic.value,
        let ASCIIstring = NSString(data: charValue, encoding: String.Encoding.utf8.rawValue) else { return }

        characteristicASCIIValue = ASCIIstring
        
        if (characteristic.isEqual(RPIcharacteristics?.cameraStateChar)){
            handleCameraState(value: "\((characteristicASCIIValue as String))")
        }
        if (characteristic.isEqual(RPIcharacteristics?.shouldTakePhotoChar)){
            handleShouldTakePhoto(value: "\((characteristicASCIIValue as String))")
        }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        current_RSSI = RSSI.floatValue
        RPIperipheral?.readRSSI()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        print("Function: \(#function),Line: \(#line)")
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")

        } else {
            print("Characteristic's value subscribed")
        }

        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
}

extension BLE: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Is Powered On.")
        case .unsupported:
            print("Peripheral Is Unsupported.")
        case .unauthorized:
        print("Peripheral Is Unauthorized.")
        case .unknown:
            print("Peripheral Unknown")
        case .resetting:
            print("Peripheral Resetting")
        case .poweredOff:
            print("Peripheral Is Powered Off.")
        @unknown default:
            print("Error")
        }
    }


    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
}
