//
//  KeynoteController.swift
//  uB1-SlideAdvance
//
//  Created by William LaFrance on 3/27/15.
//  Copyright (c) 2015 LS Research. All rights reserved.
//

import OSAKit

class KeynoteController: RemoteControllable {

    func performAction() {
        let source = "Tell Application \"Keynote\"\nshow next\nEnd Tell"

        if let language = OSALanguage(forName: "AppleScript"), script = OSAScript(source: source, language: language) {
            var errorInfo: NSDictionary?

            if !script.compileAndReturnError(&errorInfo) {
                print("Next script failed to compile: \(errorInfo)")
            }

            let result = script.executeAndReturnError(&errorInfo)
            print("Tried to show next. Result: \(result), errorInfo: \(errorInfo)")
        } else {
            print("Failed to compile script with AppleScript: \(source)")
        }
    }

}
