//
//  ImageEditorViewController.swift
//  Coffee Display
//
//  Created by Brian Rosales on 3/18/23.
//

import UIKit
/*
struct user {
    let name: String?
    let surname: String?
    let email: String?
    let phoneNumber: String?
    let password: String?
    let repeatPassword: String?
}
*/
enum TextFieldData: Int {
    
    case nameTextField = 0
    case surnameTextField
    case emailTextField
    case phoneTextField
    case passwordTextField
    case repeatPasswordTextField
    
}

// Define what header will hold.
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
        label.frame = CGRect(x: 0, y: contentView.frame.size.height-2000-label.frame.size.height, width: contentView.frame.size.width, height: label.frame.size.height)
    }
}
// Allows for Textfield to be inserted to each cell.
class RegistrationViewCell: UITableViewCell {
    var placeholder: String? {
        didSet {
            guard let item = placeholder else {return}
            dataTextField.placeholder = item
        }
    }
    
    let dataTextField: UITextField = {
            let textField = UITextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.font = UIFont.systemFont(ofSize: 20)
            return textField
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initConstraints()
       
    }
    
    func initConstraints(){
            
            addSubview(dataTextField)
            
            NSLayoutConstraint.activate([
                dataTextField.heightAnchor.constraint(equalToConstant: 40),
                dataTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                dataTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                dataTextField.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                dataTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            ])
            
        }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
}

class ImageEditorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    let placeholderData = ["Name", "Surname", "Email", "Phone number", "Password", "Repeat password"]
    // Basic overview of the table.
    let tableView: UITableView = {
    let table = UITableView()
    table.translatesAutoresizingMaskIntoConstraints = false
    table.backgroundColor = .systemGray5
    return table
    }()
    
    // Initilize table view.
    func initTableView(){
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.backgroundColor = .systemGray5
        tableView.register(RegistrationViewCell.self, forCellReuseIdentifier: "register_cell")
        //Needs work
        tableView.register(TableHeader.self, forHeaderFooterViewReuseIdentifier: "header")
        
        
         // Remove the separator from tableView.
        tableView.separatorStyle = .singleLine
        
        // Constraints for the table view.
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor
                                          )
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Image Editor"
        initTableView()
    }
    
    // Defines rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return placeholderData.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "register_cell", for: indexPath) as? RegistrationViewCell {
                cell.dataTextField.delegate = self
                cell.placeholder = placeholderData[indexPath.row]
                cell.dataTextField.tag = indexPath.row
                // MARK: Remove selection style
                cell.selectionStyle = .gray
                return cell
            }
            
            return UITableViewCell()
        }
    // Defines number of cells
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    /*
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(valueChanged), for: .editingChanged)
    }
    
    
    @objc func valueChanged(_ textField: UITextField){
            
            switch textField.tag {
            case TextFieldData.nameTextField.rawValue:
            user.name = textField.text
            case TextFieldData.surnameTextField.rawValue:
            user.surname = textField.text
                
            case TextFieldData.emailTextField.rawValue:
            user.email = textField.text
                
            case TextFieldData.phoneTextField.rawValue:
            user.phoneNumber = textField.text
                
            case TextFieldData.passwordTextField.rawValue:
            user.password = textField.text
            textField.isSecureTextEntry = true
                
            case TextFieldData.repeatPasswordTextField.rawValue:
            user.repeatPassword = textField.text
            textField.isSecureTextEntry = true
            default:
                break
            }
        }
     */
}
