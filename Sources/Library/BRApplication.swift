//
//  Application.swift
//  HomeAutomatix
//
//  Created by Bastian Rössler on 23.02.17.
//
//

#if os(Linux) || os(macOS)

#if canImport(Glibc)
import Glibc
#endif

import Foundation

open class BRApplication
{
    public static let shared = BRApplication()
    
    static let notificationApplicationWillTerminate         = Notification.Name(rawValue: "ApplicationWillTerminate")
    static let notificationApplicationDidFinishLaunching    = Notification.Name(rawValue: "ApplicationDidFinishLaunching")
    
    var exitCode: Int32? = nil
    
    open var delegate: BRApplicationDelegate? {
        didSet {
            self.delegate?.applicationDidFinishLaunching(application: self)
            NotificationCenter.default.post(name: BRApplication.notificationApplicationDidFinishLaunching, object: self)
            self.startRunLoop()
        }
    }
    
    public let launchDate = Date()
    
    public init()
    {
        signal(SIGINT) { s in
            BRApplication.shared.terminate(code: 0, sender: BRApplication.shared)
        }
        signal(SIGTERM) { (s) in
            BRApplication.shared.terminate(code: 0, sender: BRApplication.shared)
        }
    }
    
    private func startRunLoop()
    {
        RunLoop.main.run()
    }
    
    open func terminate(code: Int32, sender: AnyObject?)
    {
        if (self.delegate?.applicationShoudTerminate(application: self, sender: sender) == false)
        {
            return
        }
        
        self.delegate?.applicationWillTerminate(application: self, sender: sender)
        NotificationCenter.default.post(name: BRApplication.notificationApplicationWillTerminate, object: sender)
        
        exit(code)
    }
}
#endif
