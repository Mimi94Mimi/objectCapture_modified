//
//  BLEProgressingView.swift
//  CaptureSample
//
//  Created by ryan on 2024/6/30.
//  Copyright © 2024 Apple. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

/// This view is the BLE version of TimerView in original CaptureSample
struct BLEProgressingView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE

    private let fillColor: Color = Color.clear
    private let unprogressedColor: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    private let progressedColor: Color = .white

    private var timerDiameter: CGFloat = 50
    private var timerBarWidth: CGFloat = 5
    private var trimValue: CGFloat = 1

    init(model: CameraViewModel, diameter: CGFloat = 50, BLE_manager: BLE, barWidth: CGFloat = 5) {
        self.model = model
        self.BLE_manager = BLE_manager
        self.timerDiameter = diameter
        self.timerBarWidth = barWidth
        /// revised from TimerView
        if let BLEtriggerEveryTimer = model.BLEtriggerEveryTimer {
            if BLEtriggerEveryTimer.isRunning{
                trimValue = CGFloat(1.0) - (model.timeUntilCaptureSecs / BLE_manager.charValue!.timeInterval)
            } else {
                trimValue = CGFloat(1.0)
            }
        }
    }

    var body: some View{
        
        ZStack {

            Circle()
                .fill(fillColor)
                .frame(width: timerDiameter, height: timerDiameter)
                .overlay(
                    Circle().stroke(unprogressedColor, lineWidth: timerBarWidth)
                )
            Circle()
                .fill(Color.clear)
                .frame(width: timerDiameter, height: timerDiameter)
                .overlay(
                    Circle()
                        .trim(from: 0,
                              to: trimValue)
                        .stroke(style: StrokeStyle(lineWidth: timerBarWidth,
                                                   lineCap: .round,
                                                   lineJoin: .round))
                        .foregroundColor(progressedColor))
        }
    }
}

