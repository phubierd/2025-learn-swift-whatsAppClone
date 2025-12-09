//
//  VoiceRecording.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 8/12/25.
//

import Foundation
import AVFoundation
import Combine

// recording voice message
// storing message url
final class VoiceRecorderService {
    private var audioRecorder:AVAudioRecorder?
    private(set) var isRecording = false
    private var elaspedTime:TimeInterval = 0
    private var startTime:Date?
    private var timer:AnyCancellable?
    
    func startRecording (){
        // setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord,mode:.default)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
            print("voice recorder service: successfully setup AVAudiosession")
        }catch {
            print("voice recorder service: failed to setup av audio session")
        }
        
        //where do wanna store the voice message? URL
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileName = Date().toString(format: "dd-MM-YY 'at' HH:mm:ss") + ".m4a"
        let audioFileURL = documentPath.appendingPathComponent(audioFileName)
        
        let settings = [
            AVFormatIDKey:Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey:12000,
            AVNumberOfChannelsKey:1,
            AVEncoderAudioQualityKey:AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            startTime = Date()
            startTimer()
        }catch {
            print("voice recorder servce: failed to setup av audio recorder")
        }
    }
    
    func stopRecording(completion:((_ audioURL:URL?,_ audioDuration:TimeInterval)->Void)? = nil){
        
        guard isRecording else {return}
        let audioDuration = elaspedTime
        audioRecorder?.stop()
        isRecording = false
        timer?.cancel()
        elaspedTime = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            guard let audioURL = audioRecorder?.url else {return}
            completion?(audioURL,audioDuration)
        }catch {
            print("voice recorder service: failed to teardown av audio session")
        }
    }
    
    // remove record when user out room chat
    func tearDown(){
        let fileManager = FileManager.default
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderContents = try! fileManager.contentsOfDirectory(at:folder,includingPropertiesForKeys: nil)
        deleteRecordings(folderContents)
        print("voice recorder service: was successfully teared down")
    }
    
    private func deleteRecordings(_ urls:[URL]){
        for url in urls {
            deleteRecording(at:url)
        }
    }
    
    private func deleteRecording(at fileURL:URL){
        do{
            try FileManager.default.removeItem(at: fileURL)
            print("audio file was deleted at \(fileURL)")
        }catch{
            print("failed to delete file")
        }
    }
    
    private func startTimer(){
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink{ [weak self] _ in
                guard let startTime = self?.startTime else {return}
                self?.elaspedTime = Date().timeIntervalSince(startTime)
                print("voice recorder service: elapsedTime \(self?.elaspedTime)")
            }
    }
}
