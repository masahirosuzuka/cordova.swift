//
//  CDVConfigParser.swift
//  CordovaSwiftLib
//
//  Created by Masahiro Suzuka on 2014/10/13.
//  Copyright (c) 2014年 Masahiro Suzuka. All rights reserved.
//

import UIKit

class CDVConfigParser : NSObject, NSXMLParserDelegate {
  
  private var featureName:NSString?;
  internal var pluginsDict:NSMutableDictionary;
  internal var settings:NSMutableDictionary;
  internal var whitelistHosts:NSMutableArray;
  internal var startupPluginNames:NSMutableArray;
  internal var startpage:NSString;
  
  override init() {
    self.pluginsDict = NSMutableDictionary(capacity: 30);
    self.settings = NSMutableDictionary(capacity: 30);
    self.whitelistHosts = NSMutableArray(capacity: 30);
    self.whitelistHosts.addObject("file://*");
    self.whitelistHosts.addObject("content://*");
    self.whitelistHosts.addObject("data://*");
    self.startupPluginNames = NSMutableArray(capacity: 8);
    self.featureName = nil;
  }
  
  func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String, qualifiedName qName: String, attributes attributeDict: [NSObject : AnyObject]) {
    if elementName == "preference" {
      settings[attributeDict["name"]] = attributeDict["value"];
    }
  }
  
  func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String, qualifiedName qName: String) {
    if elementName == "feature" {
      featureName = nil;
    }
  }
  
  func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
    let message:NSString = NSString(format: "config.xml parse error line %ld col %ld", parser.lineNumber, parser.columnNumber);
    println(message);
  }
}