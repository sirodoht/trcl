//
//  AppDelegate.swift
//  trcl
//
//  Created by Tyoma Kazakov on 19.07.16.
//  Copyright © 2016 Tom Kazakov. All rights reserved.
//

// TODO: autostart


import Cocoa
import Foundation
import ServiceManagement


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Current bundle name to a constant
    let APPNAME = Bundle.main.infoDictionary!["CFBundleName"] as! String

    @IBOutlet weak var statusMenu: NSMenu!
    
    let mainStatusItem = NSStatusBar.system().statusItem(withLength: -1)
    
    var timer = Timer()
    
    // Time zone objects array
    var timeZones = [TRTimeZone]()
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        setTimeZones()
        
        buildMenu()
        
        // TODO: proper defaults settings for the shipped bundle
        
        
        UserDefaults.standard.register(defaults: [
            use24HForLocalTZ : false,
            displayDateForLocalTZ : true,
            autostart: false
            ])
        
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func menuClicked(_ sender: NSMenuItem) {
        
        
    }
    
    
    // Array of time strings
    func formatTime(_ timeZone: String, local: Bool) -> Array<String> {
        
        let timeFormatter = DateFormatter()
        let ampm = DateFormatter()
        
        var timeArray: [String] = ["",""]
        
        if local {
            if defaults.bool(forKey: use24HForLocalTZ) == true {
                timeFormatter.dateFormat = "H:mm"
                ampm.dateFormat = ""
                
            }
            else {
                timeFormatter.dateFormat = "h:mm"
                ampm.dateFormat = "a"
            }
        }
        else {
            timeFormatter.dateFormat = "h"
            ampm.dateFormat = "a"
        }
        
        timeFormatter.timeZone = TimeZone(identifier: timeZone)
        ampm.timeZone = TimeZone(identifier: timeZone)
        
        timeArray[0] = timeFormatter.string(from: Date())
        timeArray[1] = ampm.string(from: Date())
        
        return timeArray
    }
    
    
    func getDate() -> String { //    TODO: вообще-то это нет смысла вычислять два раза за секунду
        let usDateFormat = DateFormatter()
        usDateFormat.dateFormat = "MMM d"
        usDateFormat.locale = Locale(identifier: "en-US")
        return usDateFormat.string(from: Date())
    }
    
        
    // Initializing timezones set via timezones list const
    func setTimeZones() {
        
        var addedTimezone: TRTimeZone
        
        for (_, tz) in STtimeZones.enumerated() {
            addedTimezone = TRTimeZone.init(name: tz)
            timeZones.append(addedTimezone)
            
            // Populating defaults with visibility settings
            UserDefaults.standard.register(defaults: [addedTimezone.name+"Visibile" : false])
            
        }
    }
    
    
    
    // TODO: исправить внешний вид шрифта при нажатой кнопке
    // TODO: перейти на attributed для button-statusmenu
    
    func timerAction() {
        
        buildMenu()
        
        let ftz = NSMutableAttributedString(string: "")
        
        var nonvisibleCounter: Int = 0
        var previousWasLocal: Bool = false
        
        var font: NSFont
        
        font = NSFont.menuBarFont(ofSize: 10)
        //                        font = NSFont(name: name, size: pointSize) ?? systemFont
        let fontManager = NSFontManager.shared()
        font = fontManager.convert(font, toHaveTrait: .smallCapsFontMask)
        let ampmFontAttr = [ NSFontAttributeName: font ]
        
        let timeFontAttr = [ NSFontAttributeName: NSFont.menuBarFont(ofSize: 0) ]
        //        let dateFontAttr = [ NSFontAttributeName: NSFont.menuBarFontOfSize(10) ]
        let notLocalFontAttr = [ NSForegroundColorAttributeName: NSColor.gray ]
        
        
        for (index, tz) in timeZones.enumerated() {
            
            var timeArray: [String] = ["",""]
            
            //            var timeAttrString = NSAttributedString(string: "", attributes: timeFontAttributes)
            
            
            if tz.isLocal() == true {
                timeArray = formatTime(tz.name, local: true)
                
                ftz.append(NSAttributedString(string: timeArray[0], attributes: timeFontAttr))
                ftz.append(NSAttributedString(string: timeArray[1], attributes: ampmFontAttr))
                ftz.append(NSAttributedString(string: " ", attributes: ampmFontAttr))
                
                if defaults.bool(forKey: displayDateForLocalTZ) == true {
                    ftz.append(NSAttributedString(string: getDate(), attributes: ampmFontAttr))
                }
                
                previousWasLocal = true
                
            }
            else {
                
                
                if defaults.bool(forKey: tz.name+"Visible") == true {
                    
                    if previousWasLocal == true {
                        ftz.append(NSAttributedString(string: " ", attributes: ampmFontAttr))
                    }
                    
                    
                    timeArray = formatTime(tz.name, local: false)
                    
                    let rangeStart = ftz.length
                    
                    ftz.append(NSAttributedString(string: timeArray[0], attributes: timeFontAttr))
                    ftz.append(NSAttributedString(string: timeArray[1], attributes: ampmFontAttr))
                    ftz.addAttributes(notLocalFontAttr, range: NSMakeRange(rangeStart, ftz.length-rangeStart))
                    
                    if index != timeZones.count {
                        ftz.append(NSAttributedString(string: " ", attributes: ampmFontAttr))
                    }
                    
                    previousWasLocal = false
                    
                }
                else {
                    nonvisibleCounter += 1
                }
                
            }
            
        }
        
        if nonvisibleCounter == timeZones.endIndex {
            // Incrementing counter to avoid empty string
            ftz.append(NSAttributedString(string: "trcl", attributes: timeFontAttr))
        }
        
        mainStatusItem.attributedTitle = ftz
    }
    
    
    //TODO: call buildMenu only on user action (click on mainStatusItem)
    func buildMenu() {
        
        var statusItem = NSMenuItem()
        
        statusMenu.removeAllItems()
        
        // Top menu items
        
        // use24HForLocalTZ
        statusItem = NSMenuItem(title: "Local time in 24H format", action:#selector(self.toggleUse24HForLocalTZ(_:)), keyEquivalent: "")
        
        if defaults.bool(forKey: use24HForLocalTZ) == true {
            statusItem.state = NSOnState
        } else {
            statusItem.state = NSOffState
        }
        
        statusMenu.addItem(statusItem)
        
        
        // displayDateForLocalTZ
        statusItem = NSMenuItem(title: "Display local date", action:#selector(self.toggleDisplayDateForLocalTZ(_:)), keyEquivalent: "")
        
        if defaults.bool(forKey: displayDateForLocalTZ) == true {
            statusItem.state = NSOnState
        } else {
            statusItem.state = NSOffState
        }
        
        statusMenu.addItem(statusItem)
        
        
        
        // Add all timezone items
        statusMenu.addItem(NSMenuItem.separator())
        
        for (index, tz) in timeZones.enumerated() {
            
            if tz.isLocal() == true {
                statusItem = NSMenuItem(title: tz.fancyName(), action: nil, keyEquivalent: "")
                
                // Settings on visibility state for the local timezone
                defaults.set(true, forKey: tz.name+"Visible")

            } else {
                statusItem = NSMenuItem(title: tz.fancyName(), action:#selector(self.toggleVisibility(_:)), keyEquivalent: "")
            }
            
            if tz.isLocal() == false && defaults.bool(forKey: tz.name+"Visible") == true {
                statusItem.state = NSOnState
            } else {
                statusItem.state = NSOffState
            }
            
            statusItem.representedObject = timeZones[index]
            
            statusMenu.addItem(statusItem)
            
        }
        
        // Footer menu items
        statusMenu.addItem(NSMenuItem.separator())

        // autostart
        statusItem = NSMenuItem(title: "Autostart trcl", action:#selector(self.toggleAutostart(_:)), keyEquivalent: "")
        
        if defaults.bool(forKey: autostart) == true {
            statusItem.state = NSOnState
        } else {
            statusItem.state = NSOffState
        }
        
        statusMenu.addItem(statusItem)

        
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(NSMenuItem(title: "Quit", action:#selector(NSApp.terminate(_:)), keyEquivalent: ""))
        
        mainStatusItem.menu = statusMenu
        
    }
    
    
    func toggleVisibility(_ sender: NSMenuItem) {
        let tz: TRTimeZone = sender.representedObject as! TRTimeZone
        
        defaults.set(!defaults.bool(forKey: tz.name+"Visible"), forKey: tz.name+"Visible")
    }
    
    
    func toggleUse24HForLocalTZ(_ sender: NSMenuItem) {
        defaults.set(!defaults.bool(forKey: use24HForLocalTZ), forKey: use24HForLocalTZ)
    }
    
    
    func toggleDisplayDateForLocalTZ(_ sender: NSMenuItem) {
        defaults.set(!defaults.bool(forKey: displayDateForLocalTZ), forKey: displayDateForLocalTZ)
    }
    
    func toggleAutostart(_ sender: NSMenuItem) {
        defaults.set(!defaults.bool(forKey: autostart), forKey: autostart)
        
        let appBundleIdentifier = "kzkv.trclAutostartHelper" as CFString
        var autostartValue: Bool
        
        autostartValue = defaults.bool(forKey: autostart)
        
        if SMLoginItemSetEnabled(appBundleIdentifier, autostartValue) {
            if autostartValue {
                NSLog("trcl: Successfully added login item.")
            } else {
                NSLog("trcl: Successfully removed login item.")
            }
            
        } else {
            NSLog("trcl: Failed to add login item.")
        }
        
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
    }

    
}
