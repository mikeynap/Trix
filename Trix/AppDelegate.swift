//
//  AppDelegate.swift
//  Trix
//
//  Created by mnapolit on 12/1/16.
//  Copyright © 2016 Micmoo. All rights reserved.
//

import Cocoa
import Sparkle
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SUUpdaterDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    
    func updaterShouldRelaunchApplication(_ updater: SUUpdater!) -> Bool {
        print("SHOULD I?")
        return true
    }
    
    func updaterWillRelaunchApplication(_ updater: SUUpdater!) {
        print("Will Relaunch?")
    }
    
    func updater(_ updater: SUUpdater!, willInstallUpdate item: SUAppcastItem!) {
        print("Installing?")
    }
    
    
    func updaterShouldPromptForPermissionToCheck(forUpdates updater: SUUpdater!) -> Bool {
        print("Should I ask plz")
        return false
    }
    
    
    
    func userDidCancelDownload(_ updater: SUUpdater!) {
        print("canceled?")
    }
    
    func updater(_ updater: SUUpdater!, didFinishLoading appcast: SUAppcast!) {
        print("Did Finish Loading Update?")
    }
    
    
    
    func updaterDidNotFindUpdate(_ updater: SUUpdater!) {
        print("Didn't find update")
    }
    
    func updater(_ updater: SUUpdater!, didFindValidUpdate item: SUAppcastItem!) {
        print(item.dsaSignature)
        print(item.fileURL)
        print(item.versionString)
        print(item.propertiesDictionary)
    }
    
    func updater(_ updater: SUUpdater!, failedToDownloadUpdate item: SUAppcastItem!, error: Error!) {
        print("failed 2download")
        print(error)
    }
    func updaterMayCheck(forUpdates updater: SUUpdater!) -> Bool {
        print("May I check?")
        return true
    }
    
    func updater(_ updater: SUUpdater!, didAbortWithError didFailWithError: Error) {
        print("Failed...?")
        print(didFailWithError)
    }
    
    func updater(_ updater: SUUpdater!, willDownloadUpdate item: SUAppcastItem!, with request: NSMutableURLRequest!) {
        print("will download...")
    }
    
    func updater(_ updater: SUUpdater!, didCancelInstallUpdateOnQuit item: SUAppcastItem!) {
        print("Did cancel...??")
    }
    



}

