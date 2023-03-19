//
//  ImageEditorViewController.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/18/23.
//

import UIKit
class TableHeader: UITableViewHeaderFooterView {
    static let identifier = "TableHeader"
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Image Editor"
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: contentView.frame.size.height-label.frame.size.height, width: contentView.frame.size.width, height: label.frame.size.height - 100)
    }
}

class ImageEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    
    private let myArray: NSArray = ["First","Second","Third"]
    private var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myTableView = UITableView()
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.register(TableHeader.self, forHeaderFooterViewReuseIdentifier: "header")
        myTableView.dataSource = self
        myTableView.delegate = self
        self.view.addSubview(myTableView)
        // Prepare to use constraints.
        myTableView.translatesAutoresizingMaskIntoConstraints = false
        // Defines/hold constraints.
        NSLayoutConstraint.activate([
            myTableView.topAnchor.constraint(equalTo: view.topAnchor),
            myTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
    }
    
    //prints info for each cell that is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Num: \(indexPath.row)")
        print("Value: \(myArray[indexPath.row])")
    }
    // Defines number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myArray.count
    }
    
    // Defines number of cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        cell.textLabel!.text = "\(myArray[indexPath.row])"
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
}
