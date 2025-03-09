import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "com.example.practice_my_accent/audio",
                                           binaryMessenger: controller.binaryMessenger)
    
    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "forceAudioToSpeaker" {
        self.forceAudioToSpeaker(result: result)
      } else if call.method == "useDefaultAudioRouting" {
        self.useDefaultAudioRouting(result: result)
      } else if call.method == "isHeadphonesConnected" {
        result(self.isHeadphonesConnected())
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func forceAudioToSpeaker(result: FlutterResult) {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
      try AVAudioSession.sharedInstance().setActive(true)
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", 
                         message: "Failed to set audio session category: \(error.localizedDescription)",
                         details: nil))
    }
  }
  
  private func useDefaultAudioRouting(result: FlutterResult) {
    do {
      // Check if headphones are connected
      if isHeadphonesConnected() {
        // Use headphones
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowBluetooth])
      } else {
        // Use speaker for media playback
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
      }
      
      try AVAudioSession.sharedInstance().setActive(true)
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", 
                         message: "Failed to set default audio routing: \(error.localizedDescription)",
                         details: nil))
    }
  }
  
  private func isHeadphonesConnected() -> Bool {
    let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
    for output in outputs {
      if output.portType == AVAudioSession.Port.headphones ||
         output.portType == AVAudioSession.Port.bluetoothA2DP ||
         output.portType == AVAudioSession.Port.bluetoothHFP ||
         output.portType == AVAudioSession.Port.bluetoothLE ||
         output.portType == AVAudioSession.Port.airPlay {
        return true
      }
    }
    return false
  }
}
