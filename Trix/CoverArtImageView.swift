//
//  CoverArtImageView.swift
//  Trix
//
//  Created by mnapolit on 12/4/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa

class CoverArtImageView: NSImageView {
    var droppedFilePath: String?
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let imagePath = board[0] as? String {
            // THIS IS WERE YOU GET THE PATH FOR THE DROPPED FILE
            Swift.print(imagePath)
            droppedFilePath = imagePath
            return true
        }
        return false
    }
    
}
