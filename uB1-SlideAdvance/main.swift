//
//  main.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 1/19/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import Foundation

let btRemote = BluetoothRemoteController(controlledObject: TextRemoteControllable(), deviceName: "TiWi-uB1")
CFRunLoopRun()
