//
//  ViewController.swift
//  Trix
//
//  Created by mnapolit on 12/1/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa
import Sparkle

let NEncodingQuality = 4
enum EncodingQuality: Int {
    case LosslessALAC = 0
    case Lossy320AAC = 1
    case Lossy256AAC = 2
    case Lossy128AAC = 3
}

class TasksViewController: NSViewController {
    
    //Controller Outlets
    //@IBOutlet var outputText:NSTextView!
    @IBOutlet var spinner:NSProgressIndicator!
    @IBOutlet var sourcePath:NSPathControl!
    @IBOutlet var destPath:NSPathControl!
    @IBOutlet var buildButton:NSButton!
    @IBOutlet var quality:NSPopUpButton!
    @IBOutlet var progress:NSProgressIndicator!
    @IBOutlet var coverart:CoverArtImageView!
    @IBOutlet var albumTitle:NSTextField!
    
    var updater:SUUpdater?
    
    dynamic var isRunning = false
    var buildTask:Process!
    var tasks: Int = 0
    var tasksDone: Int = 0
    override func viewDidLoad() {
        self.sourcePath.url = URL(fileURLWithPath: NSHomeDirectory().appending("/Downloads"))
        var storePath = NSHomeDirectory().appending("/Music/iTunes/iTunes Media/Automatically Add to iTunes.localized")
        
        var isDir : ObjCBool = false
        if !FileManager.default.fileExists(atPath: storePath, isDirectory:&isDir){
            storePath = NSHomeDirectory().appending("/Downloads")
        }
        
        updater = SUUpdater.shared()
        
        updater?.delegate = NSApp.delegate as! SUUpdaterDelegate!
        self.destPath.url = URL.init(fileURLWithPath: storePath)
        updater?.checkForUpdates(nil)
    }
    
    @IBAction func startTask(_ sender:AnyObject) {
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        let group = DispatchGroup()
        var sourceLocation = ""
        var finalLocation = ""
        var artURL: String?
        var albumName: String?
        let fileManager = FileManager.default
        var quality: EncodingQuality = EncodingQuality.LosslessALAC
        if self.quality.indexOfSelectedItem <= NEncodingQuality {
            quality = EncodingQuality(rawValue: self.quality.indexOfSelectedItem)!
        }
        if self.albumTitle.stringValue != "" {
            albumName = self.albumTitle.stringValue
        }
        artURL = self.coverart.droppedFilePath
        if let sourceURL = sourcePath.url, let destURL = destPath.url {
            self.isRunning = true
            self.buildButton.isEnabled = false
            self.spinner.startAnimation(self)
            sourceLocation = sourceURL.path
            finalLocation = destURL.path
            
            let enumerator = fileManager.enumerator(atPath: sourceLocation)
            while let element = enumerator?.nextObject() as? String {
                if enumerator!.level > 1 {
                    continue
                }
                print(element)
                if element.hasSuffix("flac") { // checks the extension
                    if let workItem = self.flacWorkItem(flac: element, albumName: albumName, artURL: artURL, quality: quality) {
                        self.jobWillStart(flac: element)
                        queue.async(group: group, execute: workItem)
                    }
                }
            }
            self.progress.doubleValue = 1.0
            self.progress.maxValue = Double(self.tasks + 1)
            self.progress.startAnimation(nil)
        } else {
            self.buildButton.isEnabled = true
            self.spinner.stopAnimation(self)
            self.isRunning = false
            print("ERROR!")
            // error
            return
        }
        group.notify(queue: queue, execute: {
            print("All Done");
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(atPath: sourceLocation)
            while let element = enumerator?.nextObject() as? String {
                if enumerator!.level > 1 || !element.hasSuffix("m4a"){
                    continue
                }
                do {
                    let songName = sourceLocation + "/" + element
                    try FileManager.default.moveItem(atPath: songName, toPath: finalLocation.appending("/" + element))
                    try FileManager.default.removeItem(atPath: songName + "cover.jpg")
                }
                catch let error as NSError {
                    print("Couldn't move to destination: \(error)")
                }
                
            }
            print("moved!")
            self.tasks = 0
            self.tasksDone = 0
            DispatchQueue.main.async {
                self.buildButton.isEnabled = true
                self.spinner.stopAnimation(self)
                self.progress.stopAnimation(nil)
                self.isRunning = false
            }
            
        })
    }
    
    
    func flacWorkItem(flac: String, albumName: String?, artURL: String?, quality: EncodingQuality) -> DispatchWorkItem? {
        guard let ffmpeg = Bundle.main.path(forResource: "ffmpeg",ofType:"") else {
            print("Unable to locate ffmpeg")
            return nil
        }
        guard let mp4art = Bundle.main.path(forResource: "mp4art",ofType:"") else {
            print("Unable to locate mp4art")
            return nil
        }
        
        if let sourceURL = sourcePath.url {
            let songURL = sourceURL.path + "/" + flac
            let outSong = songURL + ".m4a"
            var arguments:[String] = []
            arguments.append("-y")
            arguments.append("-loglevel")
            arguments.append("verbose")
            
            arguments.append("-i")
            arguments.append(songURL)
            
            if albumName != nil {
                arguments.append("-metadata")
                arguments.append("album=\(albumName!)")
            }
            
            switch quality {
            case .LosslessALAC:
                arguments.append("-acodec")
                arguments.append("alac")
            case .Lossy320AAC:
                arguments.append("-b:a")
                arguments.append("320k")
            case .Lossy256AAC:
                arguments.append("-b:a")
                arguments.append("256k")
            case .Lossy128AAC:
                arguments.append("-b:a")
                arguments.append("128k")
            }
            arguments.append(outSong)
            var arguments2:[String] = []
            var useArtURL: String = ""
            print("artURL is \(artURL)")
            if artURL == nil {
                arguments.append(outSong + "cover.jpg")
                useArtURL = outSong + "cover.jpg"
                print("artURL is nil, using \(useArtURL) instead")
            } else {
                useArtURL = artURL!
            }
            
            arguments2.append("--add")
            arguments2.append(useArtURL)
            arguments2.append(outSong)
            
            
            let ffmpegTask = Process()
            ffmpegTask.launchPath = ffmpeg
            ffmpegTask.arguments = arguments
            
            let mp4artTask = Process()
            mp4artTask.launchPath = mp4art
            mp4artTask.arguments = arguments2
            
            
            return DispatchWorkItem(qos: .userInitiated) {
                ffmpegTask.launch()
                ffmpegTask.waitUntilExit()
                
                mp4artTask.launch()
                mp4artTask.waitUntilExit()
                
                self.jobDone(flac: flac)
                
            }
        }
        return nil
    }
    
    func jobWillStart(flac: String){
        self.tasks += 1
    }
    
    func jobDone(flac: String){
        DispatchQueue.main.async {
            self.tasksDone += 1
            self.progress.increment(by: 1.0)
        }
        print("\(self.tasksDone)/\(self.tasks)")
    }
    
    
    @IBAction func stopTask(_ sender:AnyObject) {
        if isRunning {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).suspend()
            isRunning = false
            self.buildButton.isEnabled = true
            self.spinner.stopAnimation(self)
            self.isRunning = false
            
        }
    }
}

func synced(lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}


