//
//  CLPlayerController.swift
//  BPlayer
//
//  Created by admin on 26/03/2021.
//

import UIKit
import CoreMedia
import Player
import AVFoundation

class CLPlayerController: UIViewController {
  @IBOutlet weak var playerContainerView: UIView!
  @IBOutlet weak var controlsContainerView: UIView!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var qualityButton: UIButton!
  @IBOutlet weak var progressSlider: UISlider!

  override var prefersStatusBarHidden: Bool { true }

  var player: Player!
  var url: URL? {
    didSet {
      if let url = url {
        player.url = url
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        player.playFromBeginning()

        parseHlsInfo(url: url)
      }
    }
  }
  var currentQuality = CGSize.zero {
    didSet {
      player.preferredMaximumResolution = currentQuality
//      player.preferredForwardBufferDuration = currentQuality
    }
  }
  var currentSpeed: Float = 1.0 {
    didSet {
      player.rate = currentSpeed
    }
  }
  private let hlsParser = HLSParser()
  private var hlsStreamInfos: [HLSStreamInfo] = [] {
    didSet {
      DispatchQueue.main.async { [weak self] in
        self?.reloadQualitySetting()
      }

    }
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  convenience init() {
    self.init(nibName: String(describing: Self.self), bundle: Bundle(for: Self.self))
    _ = self.view
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initPlayer()

  }

  func initPlayer() {
    player = Player()
    player.playerDelegate = self
    player.playbackDelegate = self
    player.view.frame = playerContainerView.bounds
    player.playerView.backgroundColor = .black
    addChild(player)
    playerContainerView.addSubview(player.view)
    player.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    player.didMove(toParent: self)
  }

  @IBAction func playButtonTapped(_ sender: Any) {
    if player.playbackState == .playing {
      player.pause()
    } else {
      player.playFromCurrentTime()
    }
  }

  @IBAction func rewindButtonTapped(_ sender: Any) {
    let newTime = max(player.currentTimeInterval - 15, 0)
    player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
  }
  @IBAction func forwardButtonTapped(_ sender: Any) {
    let newTime = min(player.currentTimeInterval + 15, player.maximumDuration - 1)
    player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
  }

  @IBAction func mirrorButtonTapped(_ sender: Any) {
    player.view.flipX()
  }

  @IBAction func qualityButtonTapped(_ sender: Any) {
    let alertController = UIAlertController(title: "Select Quality", message: nil, preferredStyle: .actionSheet)

    let tile = currentQuality == .zero ? "➤ Auto" : "  Auto"
    let action = UIAlertAction(title: tile, style: .default) {[weak self] _ in
      print("select quality: auto")
      self?.currentQuality = .zero
      self?.player.preferredPeakBitRate = 0
    }
    alertController.addAction(action)

    for info in hlsStreamInfos {
      if let height = info.height, let width = info.width, let infoUrl = info.url, let bandwidth = info.bandwidth {
        let size = CGSize(width: width, height: height)
        let tile = size == currentQuality ? "➤ \(height)" : "  \(height)"
        let action = UIAlertAction(title: tile, style: .default) {[weak self] _ in
          print("select quality: ", height, infoUrl)
          self?.currentQuality = size
          self?.player.preferredPeakBitRate = Double(bandwidth)

        }
        alertController.addAction(action)
      }
    }

    present(alertController, animated: true, completion: nil)
  }

  @IBAction func progressSliderValueChanged(_ sender: Any) {
    print("progressSliderValueChanged: ", progressSlider.value)
    let newTime = Double(progressSlider.value) * player.maximumDuration
    player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
  }

  private func parseHlsInfo(url: URL) {
    self.hlsStreamInfos = []
    hlsParser.parseStreamTags(url: url) { (hlsStreamInfos) in
      self.hlsStreamInfos = hlsStreamInfos
    } failedBlock: { (error) in
      print("parse error--", error!)
    }
  }

  @IBAction func speedButtonTapped(_ sender: Any) {
    let speeds: [Float] = [0.7, 0.8, 0.9, 1]
    let alertController = UIAlertController(title: "Select Speed", message: nil, preferredStyle: .actionSheet)
    for speed in speeds {
      let speedLabel = speed == 1 ? "Normal" : "\(speed)x"
      let tile = currentSpeed == speed ? "➤ \(speedLabel)" : "  \(speedLabel)"
      let action = UIAlertAction(title: tile, style: .default) {[weak self] _ in
        print("select speed: \(speed)")
        self?.currentSpeed = speed
      }
      alertController.addAction(action)
    }

    present(alertController, animated: true, completion: nil)
  }

  private func reloadQualitySetting() {
    qualityButton.isHidden = hlsStreamInfos.isEmpty
  }
}

extension CLPlayerController: PlayerDelegate, PlayerPlaybackDelegate {
  func playerReady(_ player: Player) {
    print("playerReady")
  }

  func playerPlaybackStateDidChange(_ player: Player) {
    print("playerPlaybackStateDidChange", player.playbackState)
    if player.playbackState == .playing {
      playButton.setTitle("Pause", for: .normal)
    } else {
      playButton.setTitle("Play", for: .normal)
    }
  }

  func playerBufferingStateDidChange(_ player: Player) {
    print("playerBufferingStateDidChange: ", player.bufferingState)
  }

  func playerBufferTimeDidChange(_ bufferTime: Double) {
    print("playerBufferTimeDidChange")
  }

  func player(_ player: Player, didFailWithError error: Error?) {
    print("didFailWithError", error!)
  }

  func playerCurrentTimeDidChange(_ player: Player) {

    let progress = player.currentTimeInterval / player.maximumDuration
    progressSlider.value = Float(progress)
//    print("playerCurrentTimeDidChange: ", progress)
  }

  func playerPlaybackWillStartFromBeginning(_ player: Player) {
    print("playerPlaybackWillStartFromBeginning")
  }

  func playerPlaybackDidEnd(_ player: Player) {
    print("playerPlaybackDidEnd")
  }

  func playerPlaybackWillLoop(_ player: Player) {
    print("playerPlaybackWillLoop")
  }

  func playerPlaybackDidLoop(_ player: Player) {
    print("playerPlaybackDidLoop")
  }
}

