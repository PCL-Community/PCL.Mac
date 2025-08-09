//
//  MyLocalizedError.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/9/25.
//

import Foundation

struct MyLocalizedError: LocalizedError {
    let reason: String
    var errorDescription: String? { reason }
}
