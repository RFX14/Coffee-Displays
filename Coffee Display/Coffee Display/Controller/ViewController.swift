//
//  ViewController.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/17/23.
//

import UIKit

class ViewController: UIViewController {
    var tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Starts up the tableView
        configureTableView()
        // Do any additional setup after loading the view.
    }
    
    func configureTableView() {
        //adds tableView to this view
        view.addSubview(tableView)
        //set delegates
        setTableViewDelegates()
        //set row height
        tableView.rowHeight = 100
        //pins everything to the edge
        tableView.pin(to: view)
        //set contraints
    }
    
    func setTableViewDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
        
    }

}

//This will allow the "ViewController" to be able to delegate the tableView and datasource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    //How many cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    //What cells am I showing? is what this function is asking.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() //default
    }
    
    
}
