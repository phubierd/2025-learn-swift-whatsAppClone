//
//  Date-Extensions.swift
//  WhatsAppClone
//
//  Created by Phú Chiêm on 2/12/25.
//

import Foundation

extension Date {
    
    // if today: 3:30 PM
    // if yesterday return yesterday
    // 02/15/24
    var dayOrTimeRepresentation:String{
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(self){
            dateFormatter.dateFormat = "h:mm a"
            let formattedDate = dateFormatter.string(from:self)
            return formattedDate
            
        }else if calendar.isDateInYesterday(self){
            return "Yesterday"
        }else {
            dateFormatter.dateFormat = "MM/dd/yy"
            return dateFormatter.string(from:self)
        }
    }
    
    /// 3:30 PM
    var formatToTime:String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let formattedDate = dateFormatter.string(from:self)
        return formattedDate
    }
    
    func toString(format:String)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
