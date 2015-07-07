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

        var errorInfo: NSDictionary?

        guard let language = OSALanguage(forName: "AppleScript"), script = OSAScript(source: source, language: language) where script.compileAndReturnError(nil) else {
            preconditionFailure("Failed to compile script. Source: \(source), errorInfo? \(errorInfo)")
        }

        let result = script.executeAndReturnError(&errorInfo)
        print("Tried to show next. Result: \(result), errorInfo: \(errorInfo)")
    }

}
