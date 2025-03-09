package com.example.practice_my_accent

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.practice_my_accent/audio"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceAudioToSpeaker" -> {
                    forceAudioToSpeaker(result)
                }
                "useDefaultAudioRouting" -> {
                    useDefaultAudioRouting(result)
                }
                "isHeadphonesConnected" -> {
                    result.success(isHeadphonesConnected())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun forceAudioToSpeaker(result: MethodChannel.Result) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.mode = AudioManager.MODE_NORMAL
            audioManager.isSpeakerphoneOn = true
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_MANAGER_ERROR", "Error forcing audio to speaker: ${e.message}", null)
        }
    }
    
    private fun useDefaultAudioRouting(result: MethodChannel.Result) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            // If headphones are connected, use them
            if (isHeadphonesConnected()) {
                audioManager.isSpeakerphoneOn = false
            } else {
                // Otherwise use the speaker for media playback
                audioManager.mode = AudioManager.MODE_NORMAL
                audioManager.isSpeakerphoneOn = true
            }
            
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_MANAGER_ERROR", "Error setting default audio routing: ${e.message}", null)
        }
    }
    
    private fun isHeadphonesConnected(): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            devices.any { device -> 
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET || 
                device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES || 
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP || 
                device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
        } else {
            audioManager.isWiredHeadsetOn || audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn
        }
    }
}
