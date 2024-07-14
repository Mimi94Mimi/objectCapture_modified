//
//  BLEOptionsView.swift
//  CaptureSample
//
//  Created by ryan on 2024/5/30.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "BLEOptionsView")

struct BLEOptionsView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    
    init(model: CameraViewModel, BLE_manager: BLE){
        self.model = model
        self.BLE_manager = BLE_manager
    }

    
    var body: some View {
        ZStack(alignment: .leading) {
            Color(red: 0, green: 0, blue: 0.01, opacity: 1.0)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack(){
                modeView(model, BLE_manager)
                numOfPhotoView(BLE_manager)
                angleView(BLE_manager)
                timeIntervalView(BLE_manager)
                Spacer()
            }
            .padding(.horizontal, 10.0)
        }
    }
}

class SelectedIndex: ObservableObject{
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    @Published var index: Int {
        didSet{
            if index == 1{
                BLE_manager.modeCtrlAction("fixed_angle")
            }
            else if index == 2{
                BLE_manager.modeCtrlAction("fixed_time_interval")
            }
        }
    }
    init(_ model: CameraViewModel, _ BLE_manager: BLE, _ index: Int){
        self.model = model
        self.BLE_manager = BLE_manager
        self.index = index
    }
}

struct modeView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    @StateObject var selectedIndex: SelectedIndex
    
    init(_ model: CameraViewModel, _ BLE_manager: BLE){
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().backgroundColor = .lightGray
        self.model = model
        self.BLE_manager = BLE_manager
        let init_index = BLE_manager.charValue?.mode == "fixed_angle" ? 1 : 2
        self._selectedIndex = StateObject(wrappedValue: SelectedIndex(model, BLE_manager, init_index))
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack{
                Text("fixed angle for evert shot or fixed time")
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Picker(selection: self.$selectedIndex.index, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                Text("fixed angle").tag(1)
                Text("fixed time").tag(2)
            }
            .pickerStyle(.segmented)
            Spacer()
                .frame(height: 30)
        }
    }
}

struct numOfPhotoView: View {
    @State private var value: String
    @State private var prevValue: String
    @ObservedObject var BLE_manager: BLE
    @State var showAlert = false
    @State var errorMsg = ""
    
    init(_ BLE_manager: BLE){
        UITextField.appearance().backgroundColor = .lightGray
        self.BLE_manager = BLE_manager
        self.value = String(BLE_manager.charValue!.numOfPhoto)
        /// if the current value typed in textfiled is not valid, show previous valid value
        self.prevValue = String(BLE_manager.charValue!.numOfPhoto)
    }
    
    func textfieldAlert(_ error: String) -> Alert? {
        if(error == "Value error"){
            return Alert(
                title: Text("Value error"),
                message: Text("num_of_photo should be Int"),
                dismissButton: .default(Text("Okay"))
            )
        }
        else if(error == "Invalid value"){
            return Alert(
                title: Text("Invalid value"),
                message: Text("num_of_photo should be in [1-200]"),
                dismissButton: .default(Text("Okay"))
            )
        }
        return nil
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Number of photos")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack{
                Text("specify the total number to shoot for an object. The value should be integer with range [1, 200]")
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TextField("\(value)", text: $value)
                .frame(height: 40)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    logger.log("numofphoto onsubmit")
                    let message = BLE_manager.numOfPhotoTFAction(value)
                    switch(message){
                        case "Success":
                        prevValue = value
                        break
                        
                        case "Value error":
                        errorMsg = "Value error"
                        showAlert = true
                        value = prevValue
                        break
                        
                        case "Invalid value":
                        errorMsg = "Invalid value"
                        showAlert = true
                        value = prevValue
                        break
                        
                        default:
                        break
                    }
                }
            Spacer()
                .frame(height: 30)
        }
        .alert(isPresented: self.$showAlert,
                       content: { self.textfieldAlert(errorMsg)! })
    }
}

struct angleView: View {
    @State private var value: String
    @State private var prevValue: String
    @ObservedObject var BLE_manager: BLE
    @State var showAlert = false
    @State var errorMsg = ""
    
    init(_ BLE_manager: BLE){
        UITextField.appearance().backgroundColor = .lightGray
        self.BLE_manager = BLE_manager
        self.value = String(BLE_manager.charValue!.angle)
        /// if the current value typed in textfiled is not valid, show previous valid value
        self.prevValue = String(BLE_manager.charValue!.angle)
    }
    
    func textfieldAlert(_ error: String) -> Alert? {
        if(error == "Value error"){
            return Alert(
                title: Text("Value error"),
                message: Text("angle should be Int"),
                dismissButton: .default(Text("Okay"))
            )
        }
        else if(error == "Invalid value"){
            return Alert(
                title: Text("Invalid value"),
                message: Text("angle should be in [1-45]"),
                dismissButton: .default(Text("Okay"))
            )
        }
        return nil
    }
    
    var body: some View {
        VStack{
            HStack{
                Text("Angle")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack{
                Text("specify how many angle for turntable to rotate and shot when in \"fixed angle\" mode. The value should be integer with range [1, 45]")
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TextField("\(value)", text: $value)
                .frame(height: 40)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    logger.log("angle onsubmit")
                    let message = BLE_manager.angleTFAction(value)
                    switch(message){
                        case "Success":
                        prevValue = value
                        break
                        
                        case "Value error":
                        errorMsg = "Value error"
                        showAlert = true
                        value = prevValue
                        break
                        
                        case "Invalid value":
                        errorMsg = "Invalid value"
                        showAlert = true
                        value = prevValue
                        break
                        
                        default:
                        break
                    }
                }
            Spacer()
                .frame(height: 30)
        }
        .alert(isPresented: self.$showAlert,
                       content: { self.textfieldAlert(errorMsg)! })
    }
}

struct timeIntervalView: View {
    @State private var value: String
    @State private var prevValue: String
    @ObservedObject var BLE_manager: BLE
    @State var showAlert = false
    @State var errorMsg = ""
    
    init(_ BLE_manager: BLE){
        UITextField.appearance().backgroundColor = .lightGray
        self.BLE_manager = BLE_manager
        self.value = String(BLE_manager.charValue!.timeInterval)
        /// if the current value typed in textfiled is not valid, show previous valid value
        self.prevValue = String(BLE_manager.charValue!.timeInterval)
    }
    func textfieldAlert(_ error: String) -> Alert? {
        if(error == "Value error"){
            return Alert(
                title: Text("Value error"),
                message: Text("time interval should be Float"),
                dismissButton: .default(Text("Okay"))
            )
        }
        else if(error == "Invalid value"){
            return Alert(
                title: Text("Invalid value"),
                message: Text("time interval should be in [0.2-20.0]"),
                dismissButton: .default(Text("Okay"))
            )
        }
        return nil
    }
    var body: some View {
        VStack{
            HStack{
                Text("Time interval")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack{
                Text("specify the time interval of each photo when in \"fixed time\" mode. The value should be float/integer with range [0.2, 20]")
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TextField("\(value)", text: $value)
                .frame(height: 40)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    logger.log("time interval onsubmit")
                    let message = BLE_manager.timeIntervalTFAction(value)
                    switch(message){
                        case "Success":
                        prevValue = value
                        break
                        
                        case "Value error":
                        errorMsg = "Value error"
                        showAlert = true
                        value = prevValue
                        break
                        
                        case "Invalid value":
                        errorMsg = "Invalid value"
                        showAlert = true
                        value = prevValue
                        break
                        
                        default:
                        break
                    }
                }
            Spacer()
        }
        .alert(isPresented: self.$showAlert,
                content: { self.textfieldAlert(errorMsg)! })
    }
}
