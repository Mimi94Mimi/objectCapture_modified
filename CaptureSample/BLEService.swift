import CoreBluetooth
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "BLE")

// MARK: - structures related to BLE

struct CharValue {
    var mode: String = "fixed_angle"
    var numOfPhoto: Int = 5
    var timeInterval: Double = 1.5
    var angle: Int = 3
    var cameraState: String = "idle"
    var shouldTakePhoto: String = "false"
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
    static let mode_UUID =              CBUUID(string: "187F0001-44AD-4F56-BEE4-23B6CAC3FE46")
    static let numOfPhoto_UUID =        CBUUID(string: "187F0002-44AD-4F56-BEE4-23B6CAC3FE46")
    static let timeInterval_UUID =      CBUUID(string: "187F0003-44AD-4F56-BEE4-23B6CAC3FE46")
    static let angle_UUID =             CBUUID(string: "187F0004-44AD-4F56-BEE4-23B6CAC3FE46")
    static let cameraState_UUID =       CBUUID(string: "187F0005-44AD-4F56-BEE4-23B6CAC3FE46")
    static let shouldTakePhoto_UUID =   CBUUID(string: "187F0006-44AD-4F56-BEE4-23B6CAC3FE46")
    static let connected_UUID =         CBUUID(string: "187F0007-44AD-4F56-BEE4-23B6CAC3FE46")
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
    /// current characteristic values, returns nil if the peripheral has not been found
    @Published var charValue: CharValue? = nil
    
    /// whether the current RSSI is below the lower RSSI bound (-70) or the peripheral has not been found
    @Published var isWaiting: Bool = true
    
    /// current RSSI value, returns nil if the peripheral has not been found
    @Published var current_RSSI: Float? = nil
    
    @Published var shutter: Bool? = nil
    
    /// if the peripheral cannot be found within 15 second, returns true
    @Published var peripheralMissing: Bool = false
    
    private var centralManager: CBCentralManager?
    private var RPIperipheralManager: CBPeripheralManager?
    private var RPIperipheral: CBPeripheral?
    private var cameraService: CBService?
    private var lastShouldTakePhoto: String? = nil
    private var RPIcharacteristics: Characteristics = Characteristics()
    private var nanosec_shooting_TI: UInt64? = 0
    private var connectedCounterValue: Int = 0
    private var scanTimer: Timer?
    private var RSSIbound: Float = -100
    private var connectedCounter: Timer?
    
    static let initCharValue: CharValue = CharValue()
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        disconnectFromDevice()
    }

    
    // MARK: - functions related to "finding peripherals"
    func startScanning() -> Void {
        DispatchQueue.main.async {
            self.peripheralMissing = false
        }
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
        scanTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }

    func stopScanning() -> Void {
        centralManager?.stopScan()
        DispatchQueue.main.async {
            guard let RPIperipheral = self.RPIperipheral else {
                self.peripheralMissing = true
                return
            }
            if (RPIperipheral.state != .connected) {
                self.peripheralMissing = true
                return
            }
        }
        
    }
    
    private func connectToDevice() -> Void {
        centralManager?.connect(RPIperipheral!, options: nil)
    }

    private func disconnectFromDevice() -> Void {
        if RPIperipheral != nil {
            centralManager?.cancelPeripheralConnection(RPIperipheral!)
        }
    }

    private func delayedConnection() -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.connectionEstablished()
        })
    }

    // MARK: - functions related to "after connection"
    func logCaptureTimeInterval(){
        if(nanosec_shooting_TI != 0){
            let time_after = Double(DispatchTime.now().uptimeNanoseconds - nanosec_shooting_TI!) / Double(1000000000)
            nanosec_shooting_TI = DispatchTime.now().uptimeNanoseconds
            logger.log("\(time_after)s after last shot")
        }
        else{
            nanosec_shooting_TI = DispatchTime.now().uptimeNanoseconds
        }
    }
    
    private func connectionEstablished() {
        logger.log("connectionEstablished")
        DispatchQueue.main.async {
            self.charValue = CharValue()
        }
        lastShouldTakePhoto = "false"
        writeOutgoingValue(data: "0", txChar: RPIcharacteristics.connectedChar)
        connectedCounter = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
            self.sendCounterValue()
        }
    }
    
    /// called every 0.1 seconds, if connection is good, increase the counter by 1, else switch to waiting state
    private func sendCounterValue() {
        guard let current_RSSI else {
            logger.log("sendCounterValue failed")
            return
        }
//        guard let RPIperipheral = self.RPIperipheral, let connectedChar = RPIcharacteristics.connectedChar else {return}
//        RPIperipheral.readValue(for: connectedChar)
        
        if (current_RSSI > RSSIbound) {
            connectedCounterValue += 1
            isWaiting = false
        }
        else {
            if (isWaiting == false){
                isWaiting = true
            }
        }
        writeOutgoingValue(data: String("\(connectedCounterValue)"), txChar: RPIcharacteristics.connectedChar)
    }
    
    /// check if shouldTakePhoto is changed and conduct corresponding actions
    private func handleShouldTakePhoto(_ value: String) -> Void{
        guard let _ = lastShouldTakePhoto, let _ = charValue else {
            logger.log("handleShouldTakePhoto failed")
            return
        }
        let shouldTakePhotoToChanged = lastShouldTakePhoto != self.charValue?.shouldTakePhoto
        if(shouldTakePhotoToChanged){
            if(lastShouldTakePhoto == "false") {
                writeOutgoingValue(data: "false" , txChar: RPIcharacteristics.shouldTakePhotoChar)
            }
            self.lastShouldTakePhoto = self.charValue?.shouldTakePhoto
        }
    }
    
    /// for simulating shutter
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

    private func writeOutgoingValue(data: String, txChar: CBCharacteristic?){
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        if RPIperipheral != nil {
            if let txCharacteristic = txChar {
                RPIperipheral?.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    // MARK: - UI object event handlers
    func modeCtrlAction(_ text: String) {
        DispatchQueue.main.async {
            self.charValue?.mode = text
        }
        writeOutgoingValue(data: text, txChar: RPIcharacteristics.modeChar)
        logger.log("mode -> \(String(text))")
    }
    
    /// when textfield of "number of photo" is filled and return is pressed, call this function
    func numOfPhotoTFAction(_ text: String) -> String {
        guard let input = Int(text) else {
            return "Value error"
        }
        if input < 1 || input > 200 {
            return "Invalid value"
        }
        DispatchQueue.main.async {
            self.charValue?.numOfPhoto = input
        }
        writeOutgoingValue(data: text, txChar: RPIcharacteristics.numOfPhotoChar)
        
        logger.log("numofphoto -> \(String(input))")
        return "Success"
    }

    func angleTFAction(_ text: String) -> String {
        guard let input = Int(text) else {
            return "Value error"
        }
        if input < 1 || input > 45 {
            return "Invalid value"
        }
        DispatchQueue.main.async {
            self.charValue?.angle = input
        }
        writeOutgoingValue(data: text, txChar: RPIcharacteristics.angleChar)
        
        logger.log("angle -> \(String(input))")
        return "Success"
    }
    
    func timeIntervalTFAction(_ text: String) -> String {
        guard let input = Double(text) else {
            return "Value error"
        }
        if input < 0.2 || input > 20.0 {
            return "Invalid value"
        }
        DispatchQueue.main.async {
            self.charValue?.timeInterval = input
        }
        writeOutgoingValue(data: text, txChar: RPIcharacteristics.timeIntervalChar)
        
        logger.log("angle -> \(String(format: "%.2f", input))")
        return "Success"
    }
    
    func cameraButtonAction() {
        logger.log("cameraButtonAction")
        if (charValue?.cameraState == "idle") {
            writeOutgoingValue(data: "shooting", txChar: RPIcharacteristics.cameraStateChar)
            DispatchQueue.main.async {
                self.charValue?.cameraState = "shooting"
            }
        }
        else if (charValue?.cameraState == "shooting") {
            writeOutgoingValue(data: "idle", txChar: RPIcharacteristics.cameraStateChar)
            DispatchQueue.main.async {
                self.charValue?.cameraState = "idle"
            }
        }
    }
    
    // MARK: - destruction
    private func didcloseAPP() {
        writeOutgoingValue(data: "0", txChar: RPIcharacteristics.connectedChar)
        disconnectFromDevice()
        logger.log("close captureSample APP")
    }

    deinit {
        didcloseAPP()
    }
}

extension BLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
            logger.log("centralManager is powered off.")
            case .poweredOn:
            logger.log("centralManager is powered on.")
            startScanning()
            case .unsupported:
            logger.log("centralManager is unsupported.")
            case .unauthorized:
            logger.log("centralManager is unauthorized.")
            case .unknown:
            logger.log("centralManager is unknown.")
            case .resetting:
            logger.log("centralManager is resetting.")
            @unknown default:
            logger.log("centralManagerDidUpdateState(_ central: CBCentralManager): Error")
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "raspberrypi" {

            RPIperipheral = peripheral
            RPIperipheral?.delegate = self

            logger.log("Peripheral Discovered: \(peripheral)")
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

        logger.log("Found \(characteristics.count) characteristics.")

        for characteristic in characteristics {
            if CBUUIDs.characteristic_UUIDs.contains(characteristic.uuid) {
                switch characteristic.uuid {
                    case CBUUIDs.mode_UUID:
                    RPIcharacteristics.modeChar = characteristic
                    break
                    case CBUUIDs.numOfPhoto_UUID:
                    RPIcharacteristics.numOfPhotoChar = characteristic
                    break
                    case CBUUIDs.timeInterval_UUID:
                    RPIcharacteristics.timeIntervalChar = characteristic
                    break
                    case CBUUIDs.angle_UUID:
                    RPIcharacteristics.angleChar = characteristic
                    break
                    case CBUUIDs.cameraState_UUID:
                    RPIcharacteristics.cameraStateChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    break
                    case CBUUIDs.shouldTakePhoto_UUID:
                    RPIcharacteristics.shouldTakePhotoChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    break
                    case CBUUIDs.connected_UUID:
                    RPIcharacteristics.connectedChar = characteristic
                    //peripheral.setNotifyValue(true, for: characteristic)
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

        guard let _charValue = characteristic.value,
        let _ = self.charValue,
        let ASCIIstring = NSString(data: _charValue, encoding: String.Encoding.utf8.rawValue) else { return }

        characteristicASCIIValue = ASCIIstring
        
        if (characteristic.isEqual(RPIcharacteristics.cameraStateChar)){
            DispatchQueue.main.async {
                self.charValue?.cameraState = characteristicASCIIValue as String
            }
        }
        if (characteristic.isEqual(RPIcharacteristics.shouldTakePhotoChar)){
            DispatchQueue.main.async {
                self.charValue?.shouldTakePhoto = characteristicASCIIValue as String
            }
            handleShouldTakePhoto("\((characteristicASCIIValue as String))")
        }
        if (characteristic.isEqual(RPIcharacteristics.connectedChar)){
//            logger.log("characteristic.isEqual(RPIcharacteristics.connectedChar)")
//            logger.log("\(characteristicASCIIValue as String)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        current_RSSI = RSSI.floatValue
        RPIperipheral?.readRSSI()
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
