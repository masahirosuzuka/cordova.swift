//
//  ViewController.swift
//  HelloSwift
//
//  Created by Masahiro Suzuka on 2014/09/15.
//  Copyright (c) 2014年 Masahiro Suzuka. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

class MainCommandDelegate: CDVCommandDelegateImpl {
  
  override func getCommandInstance(pluginName: String!) -> AnyObject! {
    return getCommandInstance(pluginName);
  }
  
  override func pathForResource(resourcepath: String!) -> String! {
    return super.pathForResource(resourcepath);
  }
}

class MainCommandQueue: CDVCommandQueue {
  
  override func execute(command: CDVInvokedUrlCommand!) -> Bool {
    return super.execute(command);
  }
}
