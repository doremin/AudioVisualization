//
//  ViewController.swift
//  AudioVisualization
//
//  Created by doremin on 2023/02/14.
//

import UIKit
import AVFoundation
import Accelerate

import PinLayout

class ViewController: UIViewController {
  
  var engine: AVAudioEngine!
  
  var audioVisualizer: AudioVisualizer!
  
  let fftSetup = vDSP_DFT_zop_CreateSetup(nil, 1024, .FORWARD)
  
  var previousTime: AVAudioTime?

  private var previousScaleValue: Float = 0.3

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.audioVisualizer = AudioVisualizer()
    self.view.addSubview(self.audioVisualizer)
    self.audioVisualizer.pin.vCenter().horizontally().height(self.view.frame.width)
    
    self.setupAudio()
  }

  func setupAudio() {
    self.engine = AVAudioEngine()
    
    // initializing main mixer and connect to the default output node
    _ = self.engine.mainMixerNode
    
    // prepare and start
    self.engine.prepare()
    
    do {
      try engine.start()
    } catch {
      print(error)
    }
    
    guard let url = Bundle.main.url(forResource: "music", withExtension: "mp3") else {
      print("can't found mp3 file")
      return
    }
    
    guard let audioFile = try? AVAudioFile(forReading: url) else {
      print("can't read url")
      return
    }
    
    let format = audioFile.processingFormat
    let player = AVAudioPlayerNode()
    
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, time in
      
          self.processAudioData(buffer: buffer)
      
      
    }
    
    // play music file
    player.scheduleFile(audioFile, at: nil)
    player.play()
  }
  
  func processAudioData(buffer: AVAudioPCMBuffer) {
    // 1 channel만 쓸거임
    guard let channelData = buffer.floatChannelData?[0] else { return }
//    guard let fftSetup = self.fftSetup else { return }
    let frameLength = buffer.frameLength
    
    // root mean square and interpolate
    let rmsValue = SignalProcessing.shared.rms(data: channelData, frameLength: UInt(frameLength))
    let scaleValue = SignalProcessing.shared.adjustDecibelToScale(decibel: rmsValue)
    let interpolatedResults = SignalProcessing.shared.interpolate(previous: self.previousScaleValue, current: scaleValue)
    self.previousScaleValue = scaleValue
    
    for rms in interpolatedResults {
      self.audioVisualizer.loudnessMagnitude = rms
    }
    
//  fast fourier transform
    let fftMaginitudes = SignalProcessing.shared.fft(data: channelData, setup: fftSetup!)
    self.audioVisualizer.frequencyVertices = fftMaginitudes
  }
}

