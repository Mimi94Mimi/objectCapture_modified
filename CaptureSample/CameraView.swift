/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the camera image and capture button.
*/
import Foundation
import SwiftUI

/// This is the app's primary view. It contains a preview area, a capture button, and a thumbnail view
/// showing the most recenty captured image.
struct CameraView: View {
    static let buttonBackingOpacity: CGFloat = 0.15
    
    @ObservedObject var model: CameraViewModel
    @State private var showInfo: Bool = false
    //TODO(BLE)
    @ObservedObject var BLE_manager: BLE
    @State private var showBLESettings: Bool = false
    
    let aspectRatio: CGFloat = 4.0 / 3.0
    let previewCornerRadius: CGFloat = 15.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometryReader in
                // Place the CameraPreviewView at the bottom of the stack.
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Center the preview view vertically. Place a clip frame
                    // around the live preview and round the corners.
                    VStack {
                        Spacer()
                        //TODO(CAMERA BLINK)
                        ZStack {
                            CameraPreviewView(session: model.session)
                                .frame(width: geometryReader.size.width,
                                       height: geometryReader.size.width * aspectRatio,
                                       alignment: .center)
                                .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
                                .onAppear { model.startSession() }
                                .onDisappear { model.pauseSession() }
                                .overlay(
                                    Image("ObjectReticle")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.all))
                            if (BLE_manager.charValue != nil && BLE_manager.charValue!.shouldTakePhoto == "true") {
                                ShutterBlinkView()
                            }
                        }
                        Spacer()
                    }
                    
                    VStack {
                        // The app shows this view when showInfo is true.
                        //TODO(BLE)
                        ScanToolbarView(model: model, showInfo: $showInfo, showBLESettings: $showBLESettings).padding(.horizontal)
                        if showInfo {
                            InfoPanelView(model: model)
                                .padding(.horizontal).padding(.top)
                        }
                        Spacer()
                        //TODO(BLE)
                        CaptureButtonPanelView(model: model, width: geometryReader.size.width, BLE_manager: BLE_manager)
                    }
                    //TODO(BLE)
                    .popover(isPresented: $showBLESettings) {
                        ZStack {
                            BLEOptionsView(model: model, BLE_manager: BLE_manager)
                        }
                    }
                    
                    //TODO(BLE)
                    if(BLE_manager.isWaiting){
                        ProgressView() {
                            Text("waiting for connection...")
                                .font(.title)
                                .padding(.top, 10.0)
                        }
                        .frame(width: geometryReader.size.width, height: geometryReader.size.height)
                        .background(Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.3))
                    }
                }
            }
            .navigationTitle(Text("Scan"))
            .navigationBarTitle("Scan")
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            //TODO(BLE)
            .onChange(of: showBLESettings, perform: { value in
                if !value {
                    model.commitBLESettings()
                }
            })
        }
    }
}

/// This view displays the image thumbnail, capture button, and capture mode button.
struct CaptureButtonPanelView: View {
    @ObservedObject var model: CameraViewModel
    
    /// This property stores the full width of the bar. The view uses this to place items.
    var width: CGFloat
    //TODO(BLE)
    @ObservedObject var BLE_manager: BLE
    
    var body: some View {
        // Add the bottom panel, which contains the thumbnail and capture button.
        ZStack(alignment: .center) {
            HStack {
                ThumbnailView(model: model)
                    .frame(width: width / 3)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                CaptureButton(model: model, BLE_manager: BLE_manager)
                Spacer()
            }
            HStack {
                Spacer()
                VStack{
                    //TODO(BLE)
//                    CaptureModeButton(model: model,
//                                      frameWidth: width / 3)
//                        .padding(.horizontal)
                    if BLE_manager.current_RSSI != nil{
                        Text("RSSI: \(Int(BLE_manager.current_RSSI ?? 0))")
                    } else {
                        Text("RSSI: N/A")
                    }
                    
                    switch (BLE_manager.charValue?.cameraState){
                    case "idle":
                        Text("photos left: \(BLE_manager.charValue!.numOfPhoto)")
                    case "shooting":
                        Text("photos left: \(model.photoLeft)")
                    default:
                        Text("photos left: N/A")
                    }
                }
                .padding(.trailing, 20.0)
            }
        }
    }
}

/// This is a custom "toolbar" view the app displays at the top of the screen. It includes the current capture
/// status and buttons for help and detailed information. The user can tap the entire top panel to
/// open or close the information panel.
struct ScanToolbarView: View {
    @ObservedObject var model: CameraViewModel
    @Binding var showInfo: Bool
    @Binding var showBLESettings: Bool
    
    var body: some View {
        ZStack {
            HStack {
                SystemStatusIcon(model: model)
                Button(action: {
                    print("Pressed Info!")
                    withAnimation {
                        showInfo.toggle()
                    }
                }, label: {
                    Image(systemName: "info.circle").foregroundColor(Color.blue)
                })
                Spacer()
                Button(action: {
                                    print("Pressed Setting!")
                                    withAnimation {
                                        showBLESettings.toggle()
                                    }
                                }, label: {
                                    Image(systemName: "gear.circle").foregroundColor(Color.blue)
                                })
                NavigationLink(destination: HelpPageView()) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(Color.blue)
                }
            }
            
            if showInfo {
                Text("Current Capture Info")
                    .font(.caption)
                    .onTapGesture {
                        print("showInfo toggle!")
                        withAnimation {
                            showInfo.toggle()
                        }
                    }
            }
        }
    }
}

/// This capture button view is modeled after the Camera app button. The view changes shape when the
/// user starts shooting in automatic mode.
struct CaptureButton: View {
    static let outerDiameter: CGFloat = 80
    static let strokeWidth: CGFloat = 4
    static let innerPadding: CGFloat = 10
    static let innerDiameter: CGFloat = CaptureButton.outerDiameter -
        CaptureButton.strokeWidth - CaptureButton.innerPadding
    static let rootTwoOverTwo: CGFloat = CGFloat(2.0.squareRoot() / 2.0)
    static let squareDiameter: CGFloat = CaptureButton.innerDiameter * CaptureButton.rootTwoOverTwo -
        CaptureButton.innerPadding
    
    @ObservedObject var model: CameraViewModel
    //TODO(BLE)
    @ObservedObject var BLE_manager: BLE
    
    //TODO(BLE)
    init(model: CameraViewModel, BLE_manager: BLE) {
        self.model = model
        self.BLE_manager = BLE_manager
    }
    
    //TODO(BLE)
    var body: some View {
        Button(action: {
            model.BLEcaptureButtonPressed()
        }, label: {
            if (BLE_manager.charValue?.mode == "fixed_time_interval"){
                FixedTimeIntervalCaptureButtonView(model: model, BLE_manager: BLE_manager)
            } else if (BLE_manager.charValue?.mode == "fixed_angle") {
                FixedAngleCaptureButtonView(model: model, BLE_manager: BLE_manager)
            }
        }).disabled(!model.isCameraAvailable || !model.readyToCapture)
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for automatic capture mode.
struct AutoCaptureButtonView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.red)
                .frame(width: CaptureButton.squareDiameter,
                       height: CaptureButton.squareDiameter,
                       alignment: .center)
                .cornerRadius(5)
            TimerView(model: model, diameter: CaptureButton.outerDiameter)
        }
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for manual capture mode.
struct ManualCaptureButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white, lineWidth: CaptureButton.strokeWidth)
                .frame(width: CaptureButton.outerDiameter,
                       height: CaptureButton.outerDiameter,
                       alignment: .center)
            Circle()
                .foregroundColor(Color.white)
                .frame(width: CaptureButton.innerDiameter,
                       height: CaptureButton.innerDiameter,
                       alignment: .center)
        }
    }
}

//TODO(BLE)
/// This is a helper view for the `CaptureButton`. It implements the shape for fixed time interval mode.
struct FixedTimeIntervalCaptureButtonView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    
    var body: some View {
        ZStack {
            if(model.isCountingDown){
                CountDownButtonView(model: model, BLE_manager: BLE_manager)
            } else {
                if (BLE_manager.charValue?.cameraState == "shooting"){
                    Rectangle()
                        .foregroundColor(Color.red)
                        .frame(width: CaptureButton.squareDiameter,
                               height: CaptureButton.squareDiameter,
                               alignment: .center)
                        .cornerRadius(5)
                } else if (BLE_manager.charValue?.cameraState == "idle") {
                    Circle()
                        .foregroundColor(Color.primary)
                        .frame(width: CaptureButton.innerDiameter,
                               height: CaptureButton.innerDiameter,
                               alignment: .center)
                        .cornerRadius(5)
                    Text("T")
                        .font(.largeTitle)
                        .foregroundColor(Color.black)
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter,
                               alignment: .center)
                }
            }
            BLEProgressingView(model: model, diameter: CaptureButton.outerDiameter, BLE_manager: BLE_manager)
        }
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for fixed angle mode.
struct FixedAngleCaptureButtonView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    
    var body: some View {
        ZStack {
            if(model.isCountingDown){
                CountDownButtonView(model: model, BLE_manager: BLE_manager)
            } else {
                if (BLE_manager.charValue?.cameraState == "shooting"){
                    Rectangle()
                        .foregroundColor(Color.red)
                        .frame(width: CaptureButton.squareDiameter,
                               height: CaptureButton.squareDiameter,
                               alignment: .center)
                        .cornerRadius(5)
                } else if (BLE_manager.charValue?.cameraState == "idle") {
                    Circle()
                        .foregroundColor(Color.primary)
                        .frame(width: CaptureButton.innerDiameter,
                               height: CaptureButton.innerDiameter,
                               alignment: .center)
                        .cornerRadius(5)
                    Text("A")
                        .font(.largeTitle)
                        .foregroundColor(Color.black)
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter,
                               alignment: .center)
                }
            }
            BLEProgressingView(model: model, diameter: CaptureButton.outerDiameter, BLE_manager: BLE_manager)
        }
    }
}

///button view when it's in counting down section
struct CountDownButtonView: View {
    @ObservedObject var model: CameraViewModel
    @ObservedObject var BLE_manager: BLE
    
    var body: some View {
        Circle()
            .foregroundColor(Color.red)
            .frame(width: CaptureButton.innerDiameter,
                   height: CaptureButton.innerDiameter,
                   alignment: .center)
            .cornerRadius(5)
        Text("\(Int(model.countDownValue))")
            .font(.largeTitle)
            .foregroundColor(Color.white)
            .frame(width: CaptureModeButton.toggleDiameter,
                   height: CaptureModeButton.toggleDiameter,
                   alignment: .center)
    }
}

struct ShutterBlinkView: View {
    var body: some View {
        Color.black
    }
}

//discard
struct CaptureModeButton: View {
    static let toggleDiameter = CaptureButton.outerDiameter / 3.0
    static let backingDiameter = CaptureModeButton.toggleDiameter * 2.0
    
    @ObservedObject var model: CameraViewModel
    var frameWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .center/*@END_MENU_TOKEN@*/, spacing: 2) {
            Button(action: {
                withAnimation {
                    model.advanceToNextCaptureMode()
                }
            }, label: {
                ZStack {
                    Circle()
                        .frame(width: CaptureModeButton.backingDiameter,
                               height: CaptureModeButton.backingDiameter)
                        .foregroundColor(Color.white)
                        .opacity(Double(CameraView.buttonBackingOpacity))
                    Circle()
                        .frame(width: CaptureModeButton.toggleDiameter,
                               height: CaptureModeButton.toggleDiameter)
                        .foregroundColor(Color.white)
                    switch model.captureMode {
                    case .automatic:
                        Text("A").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    case .manual:
                        Text("M").foregroundColor(Color.black)
                            .frame(width: CaptureModeButton.toggleDiameter,
                                   height: CaptureModeButton.toggleDiameter,
                                   alignment: .center)
                    }
                }
            })
            if case .automatic = model.captureMode {
                Text("Auto Capture")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        // This frame centers the view and keeps it from reflowing when the view has a caption.
        // The view uses .top so the button won't move and the text will animate in and out.
        .frame(width: frameWidth, height: CaptureModeButton.backingDiameter, alignment: .top)
    }
}

/// This view shows a thumbnail of the last photo captured, similar to the  iPhone's Camera app. If there isn't
/// a previous photo, this view shows a placeholder.
struct ThumbnailView: View {
    private let thumbnailFrameWidth: CGFloat = 60.0
    private let thumbnailFrameHeight: CGFloat = 60.0
    private let thumbnailFrameCornerRadius: CGFloat = 10.0
    private let thumbnailStrokeWidth: CGFloat = 2
    
    @ObservedObject var model: CameraViewModel
    
    init(model: CameraViewModel) {
        self.model = model
    }
    
    var body: some View {
        NavigationLink(destination: CaptureGalleryView(model: model)) {
            if let capture = model.lastCapture {
                if let preview = capture.previewUiImage {
                    ThumbnailImageView(uiImage: preview,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                } else {
                    // Use full-size if no preview.
                    ThumbnailImageView(uiImage: capture.uiImage,
                                       width: thumbnailFrameWidth,
                                       height: thumbnailFrameHeight,
                                       cornerRadius: thumbnailFrameCornerRadius,
                                       strokeWidth: thumbnailStrokeWidth)
                }
            } else {  // When no image, use icon from the app bundle.
                Image(systemName: "photo.on.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(16)
                    .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                            .fill(Color.white)
                            .opacity(Double(CameraView.buttonBackingOpacity))
                            .frame(width: thumbnailFrameWidth,
                                   height: thumbnailFrameWidth,
                                   alignment: .center)
                    )
            }
        }
    }
}

struct ThumbnailImageView: View {
    var uiImage: UIImage
    var thumbnailFrameWidth: CGFloat
    var thumbnailFrameHeight: CGFloat
    var thumbnailFrameCornerRadius: CGFloat
    var thumbnailStrokeWidth: CGFloat
    
    init(uiImage: UIImage, width: CGFloat, height: CGFloat, cornerRadius: CGFloat,
         strokeWidth: CGFloat) {
        self.uiImage = uiImage
        self.thumbnailFrameWidth = width
        self.thumbnailFrameHeight = height
        self.thumbnailFrameCornerRadius = cornerRadius
        self.thumbnailStrokeWidth = strokeWidth
    }
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: thumbnailFrameWidth, height: thumbnailFrameHeight)
            .cornerRadius(thumbnailFrameCornerRadius)
            .clipped()
            .overlay(RoundedRectangle(cornerRadius: thumbnailFrameCornerRadius)
                        .stroke(Color.primary, lineWidth: thumbnailStrokeWidth))
            .shadow(radius: 10)
    }
}
