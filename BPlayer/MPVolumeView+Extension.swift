//
//  MPVolumeView+Extension.swift
//  BPlayer
//
//  Created by admin on 29/03/2021.
//

import MediaPlayer

extension MPVolumeView {
  static let shared =  MPVolumeView()
  
  static func setVolume(_ volume: Float) {
    let volumeView = MPVolumeView()
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      slider?.value = volume
    }
  }
  
  func setVolume(_ volume: Float) {
    let slider = subviews.first(where: { $0 is UISlider }) as? UISlider
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      slider?.value = volume
    }
  }
}
