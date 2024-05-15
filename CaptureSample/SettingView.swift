//
//  SettingView.swift
//  CaptureSample
//
//  Created by cgvlab on 2024/5/13.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            Color(red: 0, green: 0, blue: 0.01, opacity: 1.0)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            ModeView(model: model)
            NumOfPhotoView(model: model)
        }
    }
}

struct ModeView: View {
    @ObservedObject var model: CameraViewModel
    @State private var selectedIndex = 1
    
    var body: some View {
        VStack {
            HStack{
                Text("Mode")
                    .font(.title2)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                    .padding(13.0)
                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                    Spacer()
            }
            Picker("", selection: $selectedIndex) {
                Text("fixed angle").tag(1)
                Text("fixed time").tag(2)
            }.pickerStyle(.segmented)
        }
    }
}

struct NumOfPhotoView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        VStack {
            HStack{
                Text("Mode")
                    .font(.title2)
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)
                    .padding(.all, 13.0)
                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                    Spacer()
            }
            Picker("", selection: $selectedIndex) {
                Text("fixed angle").tag(1)
                Text("fixed time").tag(2)
            }.pickerStyle(.segmented)
        }
    }
}

#if DEBUG
struct SettingView_Previews: PreviewProvider {
    @StateObject private static var model = CameraViewModel()
    static var previews: some View {
        SettingView(model: model)
    }
}
#endif // DEBUG

//#Preview {
//    @StateObject var model = CameraViewModel()
//    SettingView(model: model)
//}
