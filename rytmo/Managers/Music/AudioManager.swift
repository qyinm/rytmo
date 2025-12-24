//
//  AudioManager.swift
//  rytmo
//
//  Created by hippoo on 12/23/25.
//

import Foundation
import CoreAudio
import AVFoundation
import Combine

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let isDefault: Bool
    let transportType: String // "AirPods", "Built-in", etc.
    
    var iconName: String {
        if name.contains("AirPods") { return "airpodspro" }
        if name.contains("Speaker") || name.contains("스피커") { return "laptopcomputer" }
        return "speaker.wave.2"
    }
}

class AudioManager: ObservableObject {
    @Published var outputDevices: [AudioDevice] = []
    @Published var currentDeviceID: AudioDeviceID = 0
    
    var currentDeviceIcon: String {
        outputDevices.first(where: { $0.id == currentDeviceID })?.iconName ?? "headphones"
    }
    
    init() {
        refreshDevices()
        setupNotifications()
    }
    
    func refreshDevices() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propsize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize)
        
        let nDevices = Int(propsize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: nDevices)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &deviceIDs)
        
        var devices: [AudioDevice] = []
        let defaultID = getDefaultOutputDevice()
        self.currentDeviceID = defaultID
        
        for id in deviceIDs {
            if let name = getDeviceName(id), isOutputDevice(id) {
                devices.append(AudioDevice(
                    id: id,
                    name: name,
                    isDefault: id == defaultID,
                    transportType: getTransportType(id) ?? ""
                ))
            }
        }
        
        DispatchQueue.main.async {
            self.outputDevices = devices
        }
    }
    
    func setOutputDevice(_ id: AudioDeviceID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), [id])
        refreshDevices()
    }
    
    private func getDefaultOutputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propsize = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &propsize, &deviceID)
        return deviceID
    }
    
    private func getDeviceName(_ id: AudioDeviceID) -> String? {
        var name: CFString = "" as CFString
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propsize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(id, &address, 0, nil, &propsize, &name)
        return name as String
    }
    
    private func isOutputDevice(_ id: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var propsize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &address, 0, nil, &propsize)
        return propsize > 0
    }
    
    private func getTransportType(_ id: AudioDeviceID) -> String? {
        var transportType: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propsize = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(id, &address, 0, nil, &propsize, &transportType)
        
        // kAudioDeviceTransportTypeAirPlay 등 상수로 체크 가능하지만 이름 기반으로 하는 것이 더 정확할 때가 많음
        return nil
    }
    
    private func setupNotifications() {
        // 기기 변경 시 알림 리스너 등록 생략 (간결함을 위해)
    }
}

