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
  @IBOutlet weak var currentTimeLabel: UILabel!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var endClassButton: UIButton!
  @IBOutlet weak var topControlsView: UIStackView!
  @IBOutlet weak var bottomControlsView: UIStackView!

  override var prefersStatusBarHidden: Bool { true }

  var player: Player!
  var url: URL? {
    didSet {
      if let url = url {
        player.url = url
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
  private var hidingControlTimer: Timer?

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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpCloseButton()
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    setUpCloseButton()
  }

  func initPlayer() {
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    player = Player()
    player.playerDelegate = self
    player.playbackDelegate = self
    player.view.frame = playerContainerView.bounds
    player.playerView.backgroundColor = .black
    addChild(player)
    playerContainerView.addSubview(player.view)
    player.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    player.didMove(toParent: self)
    hideControls(true)
  }

  func setUpCloseButton() {
    closeButton.isHidden =  UIDevice.current.orientation.isLandscape
    endClassButton.isHidden = !closeButton.isHidden
  }

  func hideControls(_ isHidden: Bool) {
    topControlsView.isHidden = isHidden
    bottomControlsView.isHidden = isHidden
  }

  @IBAction func playButtonTapped(_ sender: Any) {
    if player.playbackState == .playing {
      player.pause()
    } else {
      player.playFromCurrentTime()
    }
  }

  @IBAction func controlsViewTappped(_ sender: Any) {
    hideControls(false)
    bottomControlsView.isHidden = false
    if let hidingControlTimer = hidingControlTimer {
      hidingControlTimer.invalidate()
    }
    hidingControlTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] (timer) in
      self?.topControlsView.isHidden = true
      self?.bottomControlsView.isHidden = true
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

  @IBAction func closeButtonTapped(_ sender: Any) {
    dismiss(animated: true, completion: nil)
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
    let currentSeconds = Int(player.currentTimeInterval)
    currentTimeLabel.text = String(format: "%02d:%02d", currentSeconds / 60, currentSeconds % 60)
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

