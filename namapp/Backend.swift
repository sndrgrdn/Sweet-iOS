//
//  Backend.swift
//  namapp
//
//  Created by Jordi Wippert on 15-12-14.
//  Copyright (c) 2014 Jordi Wippert. All rights reserved.
//

import Foundation
import UIKit

class Backend : UIViewController {
    
    let BASE_URL = "http://178.62.204.157"
    
    func endpoint_url(param: String) -> NSURL{
        var string_url = BASE_URL + param
        var url:NSURL = NSURL(string: string_url)!
        return url
    }
    
    func get(endpoint: String, getSuccess: (data: AnyObject) -> Void, getError: () -> Void) {
        let url = endpoint_url(endpoint)
        let session = NSURLSession.sharedSession()
        
        var token = self.userToken()
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            if((error) != nil) {
                println(error.localizedDescription)
            }
            var err: NSError?
            var jsonResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as AnyObject?
            
            if let httpResponse = response as? NSHTTPURLResponse {
                println(httpResponse.statusCode)
                switch httpResponse.statusCode {
                case 200...209:
                    getSuccess(data: jsonResult!)
                case 400...499:
                    println("401 status code. Redirect to login")
                    getError()
                default:
                    getError()
                }
            } else {
                // Heeft GEEN response
                println(error)
                getError()
            }
        })
        println(task.state)
        task.resume()
    }
    
    func post(endpoint: String, params: String, postSuccess: (data: NSDictionary) -> Void, postError: () -> Void) {
        var postData:NSData = params.dataUsingEncoding(NSUTF8StringEncoding)!
        var url:NSURL = endpoint_url(endpoint)
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        var token = userToken()
        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
        var reponseError: NSError?
        var response: NSURLResponse?
        var urlData: NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&reponseError)
        var error: NSError?
        
        if let httpResponse = response as? NSHTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...299:
                let jsonData:NSDictionary = NSJSONSerialization.JSONObjectWithData(urlData!, options:NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
                postSuccess(data: jsonData)
            case 400...499:
                let jsonData:NSDictionary = NSJSONSerialization.JSONObjectWithData(urlData!, options:NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
                postSuccess(data: jsonData)
            default:
                println(httpResponse.statusCode)
                postError()
            }
        }
    }
    
    func destroy(endpoint: String) {
        var url:NSURL = endpoint_url(endpoint)
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        var token = userToken()
        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        var user_id = currentUser()
        var params = "user_id=\(user_id)&_method=DELETE"
        var postData:NSData = params.dataUsingEncoding(NSUTF8StringEncoding)!
        request.HTTPBody = postData
        request.HTTPMethod = "POST"
        var reponseError: NSError?
        var response: NSURLResponse?
        var urlData: NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response, error:&reponseError)
    }
    
    func login(email: String, password: String) {
        Backend().post("/sessions", params: "email=\(email)&password=\(password)", postSuccess: { (data) -> Void in
            let success:Bool = data.valueForKey("success") as Bool
            
            if success {
                self.createUserDefaults(email, password: password, user: data)
            } else {
                var error:NSArray = data.valueForKey("errors") as NSArray
                var message:String = error[0] as String
                self.alert("Login error", message: message)
            }
        }, postError: { (err) -> Void in
            println("Error")
            self.alert("Login error", message: "Could not connect to the server. Please check your internet connection")
        })
    }
    
    func createUserDefaults(email: String, password: String, user: NSDictionary) -> Bool {
        var prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        prefs.setObject(email, forKey: "username")
        prefs.setObject(user.valueForKey("user_id"), forKey: "userid")
        prefs.setObject(user.valueForKey("access_token"), forKey: "access_token")
        prefs.setBool(true, forKey: "isloggedin")
        prefs.synchronize()
        return true
    }

    func isLoggedIn() -> Bool {
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var isLoggedIn:Bool = prefs.boolForKey("isloggedin") as Bool
        return isLoggedIn
    }
    
    func currentUser() -> NSInteger {
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var userid:NSInteger = prefs.integerForKey("userid") as NSInteger
        return userid
    }

    func userToken() -> String {
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var token:String = ""
        if let tokenvalue:String = prefs.valueForKey("access_token") as? String {
            token = prefs.valueForKey("access_token") as String!
        } else {
            println("ERROR: NO USERTOKEN()")
        }
        return token
    }
    
    func logout() -> Bool {
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var token:String = prefs.valueForKey("access_token") as String!
        var id = currentUser()
        destroy("/sessions/\(token)")
        let appDomain = NSBundle.mainBundle().bundleIdentifier
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
        return true
    }
    
    func alert(title: String, message: String, buttons:NSArray = ["OK"]) -> UIAlertView {
        var alertView:UIAlertView = UIAlertView()
        alertView.title = title
        alertView.message = message
        
        for button in buttons {
            let button:String = button as String
            alertView.addButtonWithTitle(button)
        }
        
        alertView.show()
        return alertView
    }
}
