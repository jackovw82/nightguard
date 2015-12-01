//
//  InterfaceController.swift
//  scoutwatch WatchKit Extension
//
//  Created by Dirk Hermanns on 20.11.15.
//  Copyright © 2015 private. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

    @IBOutlet var bgLabel: WKInterfaceLabel!
    @IBOutlet var deltaLabel: WKInterfaceLabel!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    @IBOutlet var batteryLabel: WKInterfaceLabel!
    @IBOutlet var chartImage: WKInterfaceImage!
    
    var NKGREEN : UIColor = UIColor.init(colorLiteralRed: 0, green: 255, blue: 0, alpha: 0)
    var NKYELLOW : UIColor = UIColor.init(colorLiteralRed: 255, green: 255, blue: 0, alpha: 0)
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        readCurrentDataForPebbleWatch()
        readChartData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func readCurrentDataForPebbleWatch() {
        // Get the current data from REST-Call
        let request : NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "https://dhe.my-wan.de/pebble")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard error == nil else {
                return
            }
            guard data != nil else {
                return
            }
            
            let json = try!NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
            guard let jsonDict :NSDictionary = json as? NSDictionary else {
                return
            }
            let bgs : NSArray = jsonDict.objectForKey("bgs") as! NSArray
            if (bgs.count > 0) {
                let currentBgs : NSDictionary = bgs.objectAtIndex(0) as! NSDictionary
                let sgv : NSString = currentBgs.objectForKey("sgv") as! NSString
                let bgdelta = currentBgs.objectForKey("bgdelta") as! NSNumber
                let time = currentBgs.objectForKey("datetime") as! NSNumber
                let battery = currentBgs.objectForKey("battery") as! NSString
                
                self.bgLabel.setText(String(sgv))
                self.colorBgLabel(self.bgLabel, bg: String(sgv))
                self.deltaLabel.setText(self.direction(bgdelta) + String(bgdelta))
                self.timeLabel.setText(self.formatTime(time))
                self.batteryLabel.setText(String(battery) + "%")
            }
        };
        task.resume()
    }
    
    // Changes the color to red if blood glucose is bad :-/
    func colorBgLabel(bgLabel : WKInterfaceLabel, bg : String) {
        guard let bgNumber : Int = Int(bg) else {
            bgLabel.setTextColor(UIColor.whiteColor())
            return;
        }
        if bgNumber > 200 {
            bgLabel.setTextColor(UIColor.redColor())
        } else if bgNumber > 180 {
            bgLabel.setTextColor(UIColor.yellowColor())
        } else {
            bgLabel.setTextColor(UIColor.whiteColor())
        }
    }
    
    func createChart(bgValues : [Int]) {
        let chartPainter : ChartPainter = ChartPainter();

        self.chartImage.setImage(chartPainter.drawImage(bgValues))
    }
    
    func readChartData() {
        // Get the current data from REST-Call
        let request : NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: "https://dhe.my-wan.de/api/v1/entries.json?count=30")!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 20)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard error == nil else {
                return
            }
            guard data != nil else {
                return
            }
            
            let jsonArray : NSArray = try!NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSArray
            var sgvValues = [Int]()
            for jsonDict in jsonArray {
                let sgv = jsonDict["sgv"] as? NSNumber
                if sgv != nil {
                    sgvValues.insert(Int(sgv!), atIndex: 0)
                }
            }
            self.createChart(sgvValues)
        };
        task.resume()
    }
    
    func direction(delta : NSNumber) -> String {
        if (delta.intValue >= 0) {
            return "+"
        }
        return ""
    }
    
    func formatTime(secondsTil01011970 : NSNumber) -> String {
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateString : String = timeFormatter.stringFromDate(NSDate(timeIntervalSince1970: secondsTil01011970.doubleValue / 1000))
        return dateString
    }
}
