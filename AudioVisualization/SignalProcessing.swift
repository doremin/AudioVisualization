//
//  SignalProcessing.swift
//  AudioVisualization
//
//  Created by doremin on 2023/02/16.
//

import Accelerate

// we'll use root means squared (RMS) for calculate the average of loudness.
// more accurate way is to use A-Weighting.

public class SignalProcessing {
  
  private init() { }
  
  public static let shared = SignalProcessing()
  
  public func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
    // A: pointer to our data (The single-precision input vector)
    // IA: stride of our data
    // C: pointer to a Float we would like to write the result of the operation
    // N: the length of the data
    var val: Float = 0.0
    // caculates the root mean square of a single-precision(float) vector
    vDSP_rmsqv(data, 1, &val, frameLength)
    
    // 데시벨로 변환 0(silent) -> 160(loudest)
    let db = self.amplitudeToDecibel(amplitude: val)
    
    return db
  }
  
  /**
   데시벨을 Circle의 scale값에 해당하는 수치로 변환하는 함수
   - Parameters:
      - decibel: 데시벨 크기
   - Returns: Circle의 scale 배수 (0.3 ~ 0.6 사이의 값)
  */
  public func adjustDecibelToScale(decibel: Float) -> Float {
    // db의 범위가 0 <= db <= 160이고 원하는 scale의 범위가 0.3 ~ 0.6이므로 아래와 같이 변환
    // 그런데 값이 5.6 ~ 5.8이 너무 많이 나와서 변화가 크지 않으므로 120 ~ 160사이의 값만 0.3 ~ 0.6으로 변환
    
    /*
    5.6 ~ 5.8이 많이 나오는 코드
    let dividor = Float(160 / 0.3)
    let adjusted = 0.3 + decibel / dividor
    */
    
    let adjustedDecibel = min(max(decibel - 120, 0), 40)
    let dividor = Float(40 / 0.3)
    let scale = 0.3 + adjustedDecibel / dividor
    
    return scale
  }

  /**
   소리의 크기를 데시벨로 변환하는 함수
   */
  private func amplitudeToDecibel(amplitude: Float) -> Float {
    return max(160 + 10 * log10f(amplitude), 0)
  }
  
  public func interpolate(previous: Float, current: Float) -> [Float] {
    return [Int](0 ... 10)
      .map { stride -> Float in
        let alpha = Float(stride) * 0.1
        let interpolated = (1 - alpha) * previous + alpha * current
        
        return interpolated
      }
  }
  
  public func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
    // output setup
    var realIn = [Float](repeating: 0, count: 1024)
    var imaginaryIn = [Float](repeating: 0, count: 1024)
    var realOut = [Float](repeating: 0, count: 1024)
    var imaginaryOut = [Float](repeating: 0, count: 1024)
    
    for i in 0 ..< 1024 {
      realIn[i] = data[i]
    }
    
    vDSP_DFT_Execute(setup, &realIn, &imaginaryIn, &realOut, &imaginaryOut)
    
    var complex = DSPSplitComplex(realp: &realOut, imagp: &imaginaryOut)
    
    var magnitudes = [Float](repeating: 0, count: 512)
    
    vDSP_zvabs(&complex, 1, &magnitudes, 1, 512)
    
    var normalizedMagnitudes = [Float](repeating: 0.0, count: 512)
    var scalingFactor = Float(25.0 / 512)
    vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, 512)
    
    return normalizedMagnitudes
  }
}
