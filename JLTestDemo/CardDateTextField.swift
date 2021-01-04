//
//  CardDateTextField.swift
//  JLTestDemo
//
//  Created by jiali on 2020/11/13.
//

import UIKit

enum CardValidationState: Int {
    case valid = 0 ,inValid = 1, complete = 2
}

class CardDateTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
        self.defaultColor = .black;
        self.errorColor = .red
        self.validText = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.defaultColor = .black;
        self.errorColor = .red
        self.validText = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var text: String? {
        didSet (newVale){
            self.rawExpiration =  self.text ?? ""
            let state = self.validationStateForField()
            self.validText = true;
            switch (state) {
                case .inValid:
                    self.validText = false; // 控制文字颜色
                    break
                default:
                    break
            }
            
            // 用富文本赋值不再触发代理方法 textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String)，如果使用text = rawExpiration就会死循环
            let attributed = NSAttributedString(string: self.rawExpiration, attributes: defaultTextAttributes)
            attributedText = attributed
        }
    }
    
    // MARK: - 属性
    var rawExpiration: String {
        set {
            let sanitizedExpiration = self.validateNumberStringReturnNewString(newValue)
            expirationMonth = (sanitizedExpiration as NSString).substringTo(index: 2)
            let temp = (sanitizedExpiration as NSString).substring(from: min(2, sanitizedExpiration.count))
            expirationYear = (temp as NSString).substringTo(index: 2)
            
        }
        
        get {
            var array: [String] = []
            if expirationMonth != nil && expirationMonth != "" {
                array.append(expirationMonth!)
            }

            if self.validationMonthState(expirationMonth: expirationMonth ?? "") == .valid {
                array.append(expirationYear!)
            }
            return array.joined(separator: " / ")
        }
    }

    var expirationMonth: String? {  // 月份
        didSet {
            var sanitizedExpiration = self.validateNumberStringReturnNewString(((expirationMonth ?? "") as NSString) as String)
            if sanitizedExpiration.count == 1 && !(sanitizedExpiration == "0") && !(sanitizedExpiration == "1") {
                sanitizedExpiration = "0" + sanitizedExpiration
            }
            expirationMonth = (sanitizedExpiration as NSString).substring(to: min(2, sanitizedExpiration.count))
        }
    }
    
    var expirationYear: String? {   // 年份
        didSet {
            let temp = (self.validateNumberStringReturnNewString(expirationYear ?? "")
                as NSString)
            expirationYear = temp.substring(to: min(2, temp.length))
        }
    }
    
    var errorColor: UIColor? {
        didSet {
            self.updateColor()
        }
    }
    
    var defaultColor: UIColor? {
        didSet {
            self.updateColor()
        }
    }
    
    var validText: Bool? {
        didSet {
            self.updateColor()
        }
    }
}

extension CardDateTextField {
    // MARK: - Define Method
    func updateColor() {
        textColor = validText ?? true ? defaultColor : errorColor
    }
    
    // 校验月份
    func validationMonthState(expirationMonth: String) -> CardValidationState {
        
        let sanitizedExpiration = expirationMonth
        
        if !self.validateNumberString(expirationMonth) {
            return .inValid
        }
        
        switch sanitizedExpiration.count {
        case 0:
            return .complete
        case 1:
            return (((sanitizedExpiration == "0") || (sanitizedExpiration == "1")) ? .complete : .valid)
        case 2:
            return ((0 < Int(sanitizedExpiration) ?? 0 && Int(sanitizedExpiration) ?? 0 <= 12) ? .valid : .inValid)
        default:
            return .inValid
        }
    }

    // 检验输入框输入是否符合要求
    func validationStateForField()  -> CardValidationState  {
        let monthState =  self.validationMonthState(expirationMonth: expirationMonth ?? "")
        let yearState = self.validationState(forYear: expirationYear, inMonth: expirationMonth)
        if monthState == .valid && yearState == .valid {
            return .valid
        } else if monthState == .inValid || yearState == .inValid {
            return .inValid
        } else {
            return .complete
        }
    }
    
    // 检验年月
    func validationState (
        forYear expirationYear: String?,inMonth expirationMonth: String?) -> CardValidationState {
        return self.validationState(
            forExpirationYear: expirationYear,
            inMonth: expirationMonth,
            inCurrentYear: self.currentYear(),
            currentMonth: self.currentMonth())
    }
    
    func currentYear() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.component(.year, from:  Date())
        return (dateComponents) % 100
    }

    func currentMonth() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.component(.month, from: Date())
        return dateComponents
    }
    
    func validationState(forExpirationYear expirationYear: String?, inMonth expirationMonth: String?, inCurrentYear currentYear: Int, currentMonth: Int) -> CardValidationState {
        let moddedYear = currentYear % 100
        
        if !self.validateNumberString(expirationMonth ?? "") || !self.validateNumberString(expirationYear ?? "") {
            return .inValid
        }
        
        let sanitizedMonth = self.validateNumberStringReturnNewString(expirationMonth ?? "")
        let sanitizedYear = self.validateNumberStringReturnNewString(expirationYear ?? "")

        switch sanitizedYear.count {
        case 0, 1:
            return .complete
        case 2:
            if validationMonthState(expirationMonth: sanitizedMonth) == .inValid {
                return .inValid
            } else {
                if Int(sanitizedYear) == moddedYear {
                    return (Int(sanitizedMonth) ?? 0) >= currentMonth ? .valid : .inValid
                } else {
                    return (Int(sanitizedYear) ?? 0) > moddedYear ? .valid : .inValid
                }
            }
        default:
            return .inValid
        }
    }

    // 是否是数字
    func validateNumberString(_ string: String) -> Bool {
        let dateRegEx = "^\\d{0,}$"
        let dateTest = NSPredicate(format: "SELF MATCHES %@", dateRegEx)
        return dateTest.evaluate(with: string)
    }
    
    //  是数字直接返回，不是返回""
    func validateNumberStringReturnNewString(_ string: String) -> String {
        if self.validateNumberString(string) {
            return string
        } else {
            return ""
        }
    }
}

extension CardDateTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var inputText: String?
        var newString = ""
        let deleting = range.location == textField.text!.count - 1 && range.length == 1 && (string == "")
        if deleting { // 光标在最后且是按了删除键
            newString = (textField.text! as NSString).replacingOccurrences(of: " / ", with: "")
            newString = (newString as NSString).substringTo(index: newString.count - 1)
        }else {
            newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            newString = (newString as NSString).replacingOccurrences(of: " / ", with: "")
        }
        // 前面需要先把"/"替换掉再去走下面的代码，因为下面校验只能是0～9的数字
        let result = self.validateNumberString(newString)
        if result { // true 使用新的字符串
            inputText = newString
        }else {     // false 保留的字符串
            inputText = textField.text
        }

        if textField.text == inputText {
            return false
        }

        // 赋值，需要重写系统的text方法
        textField.text = inputText
        return false
    }
}

extension NSString {
    func substringTo(index: Int) -> String {
        return self.substring(to: min(index, self.length))
    }
}
