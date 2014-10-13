//
//  CDVScreenOrientationDelegate.swift
//  CordovaSwiftLib
//
//  Created by Masahiro Suzuka on 2014/10/05.
//  Copyright (c) 2014年 Masahiro Suzuka. All rights reserved.
//

import Foundation

protocol CDVScreenOrientationDelegate {
  
  func supporttedInterfaceOrientations();
  func shouldAutoroteteToInterfaceOrientaion(interfaceOrientation: UIInterfaceOrientation);
  func shouildAutorotate();
  
}