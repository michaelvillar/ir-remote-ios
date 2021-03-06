//
//  ViewController.swift
//  Remote
//
//  Created by Michaël Villar on 7/25/15.
//  Copyright (c) 2015 michaelvillar. All rights reserved.
//

import UIKit
import LIFXHTTPKit

private let greenColor:UIColor = UIColor(red: 0.3137, green: 0.7608, blue: 0.2667, alpha: 1.0)
private let redColor:UIColor = UIColor(red: 0.7687, green: 0.2616, blue: 0.2538, alpha: 1.0)
private let purpleColor:UIColor = UIColor(red: 0.4493, green: 0.2424, blue: 0.7719, alpha: 1.0)
private let grayColor:UIColor = UIColor(red: 0.7608, green: 0.7609, blue: 0.7608, alpha: 1.0)
private let yellowColor:UIColor = UIColor(red: 0.8436, green: 0.692, blue: 0.0, alpha: 1.0)

class ViewController: UIViewController, UIGestureRecognizerDelegate, IRSenderDelegate {
  
  private var colorsForKeys:[String:UIColor] = [String:UIColor]()
  private let sender:IRSender!
  private let label:UILabel = UILabel(frame: CGRectZero)
  private var lightButton:CircleButton?
  private var allLights:LightTarget?
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    self.sender = IRSender(ip: MVHost)
    
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
    self.colorsForKeys["power_on"] = greenColor
    self.colorsForKeys["power_off"] = redColor
    self.colorsForKeys["volume_up"] = purpleColor
    self.colorsForKeys["volume_down"] = purpleColor
    self.colorsForKeys["input_apple"] = grayColor
    self.colorsForKeys["input_wii"] = grayColor
    self.colorsForKeys["light"] = yellowColor
    self.colorsForKeys["light_color"] = yellowColor
    
    for (key, commands) in MVCommands {
      for command in commands {
        command.userInfo = self.colorsForKeys[key]
      }
    }
    
    self.sender.delegate = self
    self.reconnect()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.blackColor()
    
    let rows:CGFloat = 4
    let buttonSize:CGFloat = 76
    
    let horizontalSpacing:CGFloat = 40
    let verticalSpacing:CGFloat = 60
    
    let centerX = self.view.bounds.width / 2
    let startX = centerX - 20 - buttonSize
    
    let centerY = self.view.bounds.height / 2
    let startY = centerY - ((rows - 1) * verticalSpacing + rows * buttonSize) / 2
    
    let power_on = CircleButton(
      frame: CGRectMake(startX, startY, buttonSize, buttonSize),
      key: "power_on",
      color: self.colorsForKeys["power_on"],
      image: UIImage(named: "power_on")
    )
    power_on.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(power_on)
    
    let power_off = CircleButton(
      frame: CGRectMake(startX + buttonSize + horizontalSpacing, startY, buttonSize, buttonSize),
      key: "power_off",
      color: self.colorsForKeys["power_off"],
      image: UIImage(named: "power_off")
    )
    power_off.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(power_off)
    
    let input_apple = CircleButton(
      frame: CGRectMake(startX, startY + (buttonSize + verticalSpacing) * 1, buttonSize, buttonSize),
      key: "input_apple",
      color: self.colorsForKeys["input_apple"],
      image: UIImage(named: "input_apple")
    )
    input_apple.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(input_apple)
    
    let input_wii = CircleButton(
      frame: CGRectMake(startX + buttonSize + horizontalSpacing, startY + (buttonSize + verticalSpacing) * 1, buttonSize, buttonSize),
      key: "input_wii",
      color: self.colorsForKeys["input_wii"],
      image: UIImage(named: "input_wii")
    )
    input_wii.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(input_wii)
    
    let volume_down = CircleButton(
      frame: CGRectMake(startX, startY + (buttonSize + verticalSpacing) * 2, buttonSize, buttonSize),
      key: "volume_down",
      color: self.colorsForKeys["volume_down"],
      image: UIImage(named: "volume_down")
    )
    volume_down.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(volume_down)
    
    let volume_up = CircleButton(
      frame: CGRectMake(startX + buttonSize + horizontalSpacing, startY + (buttonSize + verticalSpacing) * 2, buttonSize, buttonSize),
      key: "volume_up",
      color: self.colorsForKeys["volume_up"],
      image: UIImage(named: "volume_up")
    )
    volume_up.addTarget(self, action: #selector(handleButton), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(volume_up)
    
    let light = CircleButton(
      frame: CGRectMake(startX, startY + (buttonSize + verticalSpacing) * 3, buttonSize, buttonSize),
      key: "light",
      color: self.colorsForKeys["light"],
      image: UIImage(named: "light")
    )
    light.addTarget(self, action: #selector(toggleLight), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(light)
    lightButton = light
    
    let light_color = CircleButton(
      frame: CGRectMake(startX + buttonSize + horizontalSpacing, startY + (buttonSize + verticalSpacing) * 3, buttonSize, buttonSize),
      key: "light_color",
      color: self.colorsForKeys["light_color"],
      image: UIImage(named: "light_color")
    )
    light_color.addTarget(self, action: #selector(randomLightColor), forControlEvents: UIControlEvents.TouchUpInside);
    self.view.addSubview(light_color)
  }
  
  func handleButton(button:CircleButton) {
    sendCommand(button.key)
  }
  
  func getLights(callback:((LightTarget) -> ())) {
    if (self.allLights != nil) {
      return callback(self.allLights!)
    }

    let client = Client(accessToken: MVLIFXKey)
    client.fetch() { (error) in
      if (error.count > 0) {
        self.displayError(error[0].description)
      } else {
        let all = client.allLightTarget()
        if (all.count <= 0) {
          self.displayError("Couldn't find any light")
        } else {
          self.allLights = all
          callback(all)
        }
      }
    }
  }
  
  func toggleLight() {
    animateSignal(yellowColor)
    getLights { (all) in
      if let lightTarget = all.toLightTargets().first {
        self.updateLightButton(!lightTarget.power)
        all.setPower(!lightTarget.power)
      }
    }
  }
  
  func randomLightColor() {
    let hue = Double(Float(arc4random()) / Float(UINT32_MAX))  * 360
    let saturation = Double(Float(arc4random()) / Float(UINT32_MAX)) * 60 / 100
    let color = Color(hue: hue, saturation: saturation, kelvin: 3500)
    animateSignal(yellowColor)
    getLights { (all) in
      all.setState(color, brightness: 1.0, power: true, duration: 0.5, completionHandler: { (results, error) in
        if (error != nil) {
          self.displayError(error?.description ?? "Couldn't change the color")
        }
      })
    }
  }
  
  func reconnect() {
    self.sender.connect()
    
    getLights { (all) in
      self.updateLightButton(all.power)
    }
  }
  
  private func updateLightButton(power:Bool) {
    if (power) {
      lightButton?.image = UIImage(named: "light")
    } else {
      lightButton?.image = UIImage(named: "light_off")
    }
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  func sendCommand(key:String) {
    if let cmds = MVCommands[key] {
      for cmd in cmds {
        sender.send(cmd)
      }
    }
  }
  
  private func animateSignal(color: UIColor) {
    let startY = self.view.subviews[0].frame.origin.y
    let width:CGFloat = 192
    
    let signalView = UIView(frame: CGRectMake(self.view.bounds.width / 2 - width / 2, startY / 2 - 1, width, 2))
    signalView.backgroundColor = color
    signalView.transform = CGAffineTransformMakeScale(12.0 / width, 1)
    self.view.addSubview(signalView)
    
    UIView.animateWithDuration(0.5,
      delay: 0,
      options: UIViewAnimationOptions.CurveEaseInOut,
      animations: {
        signalView.transform = CGAffineTransformIdentity
      }) { (bool) -> Void in
    }
    
    UIView.animateWithDuration(0.5,
      delay: 0,
      options: UIViewAnimationOptions.CurveEaseIn,
      animations: {
        signalView.alpha = 0.0
      }) { (bool) -> Void in
        signalView.removeFromSuperview()
    }
  }
  
  private func displayError(error: String) {
    let startY = self.view.subviews[0].frame.origin.y
    let width:CGFloat = 192
    label.frame = CGRectMake(self.view.bounds.width / 2 - width / 2, startY / 2 - 13, width, 26)
    label.backgroundColor = UIColor.clearColor()
    label.textColor = UIColor(red: 0.7608, green: 0.7608, blue: 0.7608, alpha: 0.5)
    label.textAlignment = NSTextAlignment.Center
    label.text = "You are not connected"
    label.alpha = 1.0
    self.view.addSubview(label)
    
    UIView.animateWithDuration(0.5,
                               delay: 0.85,
                               options: UIViewAnimationOptions.CurveEaseIn,
                               animations: {
                                self.label.alpha = 0.0
    }) { (bool) -> Void in
      if bool {
        self.label.removeFromSuperview()
      }
    }
  }
  
  // IRSenderDelegate
  func senderDidSendCommand(sender: IRSender, cmd: IRCommand) {
    animateSignal(cmd.userInfo as! UIColor)
  }
  
  func senderDidFailToSendCommand(sender: IRSender, cmd: IRCommand) {
    displayError("You are not connected")
  }

}

