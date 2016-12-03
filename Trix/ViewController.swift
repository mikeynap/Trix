//
//  ViewController.swift
//  Trix
//
//  Created by mnapolit on 12/1/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa
import Sparkle
class TasksViewController: NSViewController {
    
    //Controller Outlets
    @IBOutlet var outputText:NSTextView!
    @IBOutlet var spinner:NSProgressIndicator!
    @IBOutlet var sourcePath:NSPathControl!
    @IBOutlet var destPath:NSPathControl!
    @IBOutlet var buildButton:NSButton!
    var updater:SUUpdater?
    
    dynamic var isRunning = false
    var buildTask:Process!
    var tasks: Int = 0
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
        updater?.automaticallyChecksForUpdates = true
        updater?.automaticallyDownloadsUpdates = true
    
        updater?.checkForUpdateInformation()
        updater?.checkForUpdatesInBackground()
        updater?.installUpdatesIfAvailable()

    }
    
    @IBAction func startTask(_ sender:AnyObject) {
        var queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
        var group = DispatchGroup()
        var sourceLocation = ""
        var finalLocation = ""
        if let sourceURL = sourcePath.url, let destURL = destPath.url {
            self.isRunning = true
            self.buildButton.isEnabled = false
            self.spinner.startAnimation(self)
            sourceLocation = sourceURL.path
            finalLocation = destURL.path
            
            let fileManager = FileManager.default
            let enumerator = fileManager.enumerator(atPath: sourceLocation)
            while let element = enumerator?.nextObject() as? String {
                if enumerator!.level > 1 {
                    continue
                }
                print(element)
                if element.hasSuffix("flac") { // checks the extension
                    if let workItem = self.workItem(flac: element) {
                        queue.async(group: group, execute: workItem)

                    }
                }
            }
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
            self.buildButton.isEnabled = true
            self.spinner.stopAnimation(self)
            self.isRunning = false

        })

    }
    
    
    func workItem(flac: String) -> DispatchWorkItem? {
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
            arguments.append("-acodec")
            arguments.append("alac")
            arguments.append(outSong)
            arguments.append(outSong + "cover.jpg")
            
            var arguments2:[String] = []
            arguments2.append("--add")
            arguments2.append(outSong + "cover.jpg")
            arguments2.append(outSong)

            
            var ffmpegTask = Process()
            ffmpegTask.launchPath = ffmpeg
            ffmpegTask.arguments = arguments
            
            var mp4artTask = Process()
            mp4artTask.launchPath = mp4art
            mp4artTask.arguments = arguments2


            return DispatchWorkItem {
                ffmpegTask.launch()
                ffmpegTask.waitUntilExit()
                
                mp4artTask.launch()
                mp4artTask.waitUntilExit()
                
            }
        }
        return nil
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

