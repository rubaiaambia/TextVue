//
//  SCNTextNode.swift
//  TextVue
//
//  Created by Justin Cook on 9/3/21.
//

import Foundation
import SwiftUI
import ARKit

public class SCNTextNode: SCNNode{
    var textView: UITextView!
    
    init(textView: UITextView){
        self.textView = textView
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
