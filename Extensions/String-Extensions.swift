//
//  String-Extensions.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 1/12/25.
//

import Foundation

extension String{
    var isEmptyOrWhiteSpace: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
