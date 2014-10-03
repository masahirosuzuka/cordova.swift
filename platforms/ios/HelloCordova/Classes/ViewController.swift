//
//  ViewController.swift
//  HelloSwift
//
//  Created by Masahiro Suzuka on 2014/09/15.
//  Copyright (c) 2014年 Masahiro Suzuka. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel!
  
  @IBAction func print(sender: UIButton) {
    label.text = "Hello Swift";
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    println("HelloSwift");
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

