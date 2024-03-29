//
//  CaseViewController.swift
//  namapp
//
//  Created by Jordi Wippert on 25-11-14.
//  Copyright (c) 2014 Jordi Wippert. All rights reserved.
//

import UIKit

class CaseViewController: ApplicationViewController, DictControllerProtocol, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var emptyCaseViewBG: UIImageView!
    @IBOutlet weak var emptyCaseViewText: UILabel!
    @IBOutlet weak var caseType: UILabel!
    @IBOutlet weak var caseStatus: UILabel!
    @IBOutlet weak var caseStatusColor: UIView!
    @IBOutlet weak var documentsTableView: UITableView!
    
    let backend = Backend()
    let spinner = LoadingSpinner()
    
    var caseitem : CaseItem?
    var documents = [Document]()
    lazy var api : DictController = DictController(delegate: self)
    
    override func viewDidLoad() {
        self.tabBarController?.title = "\(caseitem!.title)"
        super.viewDidLoad()
        
        spinner.startLoadingSpinner(view)
        
        caseType.text = caseitem!.casetype.uppercaseString
        caseStatus.text = caseitem!.status.uppercaseString
        caseStatusColor.addStatusColor(caseitem!)
        caseStatusColor.roundedCorners(5.0)
        
        if caseitem != nil {
            api.caseUrl(caseitem!.id, { () -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    println("API Success Callback")
                    self.checkIfHasDocument()
                    self.spinner.stopLoadingSpinner()
                }
            }, error: { (err) -> Void in
                self.spinner.stopLoadingSpinner()
                var alert = self.backend.alert("Internet error", message: "Could not connect to the server. Please check your internet connection or try again in a few minutes...", buttons: ["Take me to login"])
                alert.delegate = self
            })
        }
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        switch buttonIndex{
        case 0:
            self.backend.logout()
            self.performSegueWithIdentifier("goto_login", sender: self)
        default:
            println("error")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DocumentCell") as DocumentCell
        let document = documents[indexPath.row]
        
        cell.removeCaseSelectedStyling()
        cell.addDataInCellsForDocuments(document)
        
        if(documents.count > 0) {
            if(indexPath.row == (documents.count-1)) {
                // if it's the last cell, add shadow
                cell.applyPlainShadow()
            } else {
                cell.removeShadow()
            }
        }
        
        return cell
    }
    
    func checkIfHasDocument() {
        if(documents.count > 0) {
            emptyCaseViewBG.hideElement()
            emptyCaseViewText.hideElement()
        } else {
            emptyCaseViewBG.showElement()
            emptyCaseViewText.showElement()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //        var document = documents[indexPath.row]
        let indexPath = tableView.indexPathForSelectedRow()
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as DocumentCell
        
        currentCell.addCaseSelectedStyling()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "docSegue" {
            var documentViewController: DocumentViewController = segue.destinationViewController as DocumentViewController
            var documentIndex = documentsTableView!.indexPathForSelectedRow()!.row
            var selectedDocument = self.documents[documentIndex]
            documentViewController.document = selectedDocument
        }
    }
    
    
    func didReceiveAPIResults(results: NSDictionary) {
        var resultsArr: NSDictionary = results as NSDictionary
        dispatch_async(dispatch_get_main_queue(), {
            self.documents = Document.documentsWithJSON(resultsArr)
            self.documentsTableView.reloadData()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
}