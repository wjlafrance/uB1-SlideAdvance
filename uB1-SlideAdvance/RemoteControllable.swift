//
//  RemoteControllable.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

protocol RemoteControllable {
    func performAction()
}

struct TextRemoteControllable : RemoteControllable {
    func performAction() { print("performAction()") }
}
