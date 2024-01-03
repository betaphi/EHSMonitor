//
//  BRApplicationDelegate.swift
//  HomeAutomatix
//
//  Created by Bastian Rössler on 24.02.17.
//
//

#if os(Linux) || os(macOS)
import Foundation

public protocol BRApplicationDelegate
{
    func applicationDidFinishLaunching(application: BRApplication)
    func applicationShoudTerminate(application: BRApplication, sender: AnyObject?) -> Bool
    func applicationWillTerminate(application: BRApplication, sender: AnyObject?)
}

public extension BRApplicationDelegate
{
    func applicationDidFinishLaunching(application: BRApplication) { return }
    func applicationShoudTerminate(application: BRApplication, sender: AnyObject?) -> Bool { return true }
    func applicationWillTerminate(application: BRApplication, sender: AnyObject?) { return }
}
#endif
