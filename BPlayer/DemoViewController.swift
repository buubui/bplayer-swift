//
//  DemoViewController.swift
//  BPlayer
//
//  Created by admin on 24/03/2021.
//

import UIKit

class DemoViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let videoUrl = URL(string: "https://d2t9el598942m2.cloudfront.net/MovementSpeaks_2221_Brandon_Oneal_BegJazz/MovementSpeaks_2221_Brandon_Oneal_BegJazz.m3u8")
    print("aaa--", videoUrl)
    let player = CLPlayerController()
    player.url = videoUrl
    present(player, animated: true)
  }
}

