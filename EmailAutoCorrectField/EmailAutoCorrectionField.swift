//
//  EmailAutoCorrectionField.swift
//  EmailAutoCorrectField
//
//  Created by Lonelie on 2022/05/19.
//

import UIKit

public class EmailAutoCorrectionField: UITextField {
    private let candidates: [String] = [
        "gmail.com",
        "naver.com",
        "daum.net",
        "hanmail.net",
        "nate.com",
        "kakao.com",
        "me.com",
        "icloud.com",
        "mac.com",
        "yahoo.com",
        "mail.com",
        "msn.com",
        "hotmail.com",
        "outlook.com",
        "outlook.co.kr",
        "chol.com",
        "korea.com",
        "aol.com",
        "lycos.com"
    ]
    
    private let label = UILabel(frame: .zero)
    
    public var candidateColor: UIColor = .placeholderText
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.initView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initView()
    }
    
    private func initView() {
        self.spellCheckingType  = .no
        self.autocorrectionType = .no
        self.keyboardType       = .emailAddress
        self.returnKeyType      = .done
        self.borderStyle        = .none
        
        self.addSubview(self.label)
        self.bringSubviewToFront(self.label)
        self.label.backgroundColor          = .clear
        self.label.font                     = self.font
        self.label.isUserInteractionEnabled = false
        
        super.addTarget(self, action: #selector(self.editingChanged), for: .editingChanged)
        super.addTarget(self, action: #selector(self.editingDidEnd),  for: .editingDidEnd)
        super.addTarget(self, action: #selector(self.editingDidEnd),  for: .editingDidEndOnExit)
    }
}

extension EmailAutoCorrectionField {
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.bounds
    }
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer.name {
        case "UITextInteractionNameSingleTap" where self.isFirstResponder:
            let location = gestureRecognizer.location(in: self)
            let textSize = self.getTextSize()
            if location.x > textSize.width {
                self.correctToEmail()
                return false
            }
        default:
            break
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension EmailAutoCorrectionField {
    private func showCandidate(currentText: String, candidate: String) {
        guard let font = self.font else { return }
        let attributedString = NSMutableAttributedString(string: String(format: "%@%@", currentText, candidate),
                                                         attributes: [.font: font,
                                                                      .foregroundColor: UIColor.clear])
        attributedString.setAttributes([.font: font,
                                        .foregroundColor: self.candidateColor],
                                       range: .init(location: currentText.count, length: candidate.count))
        self.label.attributedText = attributedString
    }
    
    public func correctToEmail() {
        guard let autocorrectedString = self.label.attributedText?.string,
              let currentString       = self.text,
              autocorrectedString.prefix(currentString.count) == currentString
        else { return }
        self.label.attributedText = .init(string: "")
        self.text = autocorrectedString
    }
    
    private func getTextSize() -> CGSize {
        guard let text = self.text,
              let font = self.font
        else { return .zero }
        let rect = text.boundingRect(with:       self.bounds.size,
                                     options:    .usesLineFragmentOrigin,
                                     attributes: [.font: font],
                                     context:    nil)
        return rect.size
    }
}

extension EmailAutoCorrectionField {
    @objc
    private func editingChanged(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let index = text.firstIndex(of: "@") {
            let location = text.distance(from: text.startIndex, to: index)
            let host = text.subString(start: location + 1)
            if let candidate = self.candidates.filter({ $0.prefix(host.count) == host }).first {
                self.showCandidate(currentText: text, candidate: candidate.subString(start: host.count))
            } else {
                self.label.attributedText = .init(string: "")
            }
        } else {
            self.label.attributedText = .init(string: "")
        }
    }
    
    @objc
    private func editingDidEnd(_ textField: UITextField) {
        self.correctToEmail()
    }
}

extension String {
    fileprivate var nsString: NSString { self as NSString }
    
    fileprivate var isBackspaceCharacter: Bool {
        guard let cstring = self.cString(using: String.Encoding.utf8) else { return false }
        return strcmp(cstring, "\\b") == -92
    }
    
    fileprivate func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    fileprivate func subString(start: Int) -> String {
        if start >= self.lengthOfBytes(using: String.Encoding.utf8) {
            return ""
        }
        let stringArray = self.map({ String($0) })
        return Array(stringArray[start..<stringArray.count]).reduce("", { $0 + $1 })
    }
}
