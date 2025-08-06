//
//  ThemeParseTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/5/25.
//

import Foundation
import Testing
import SwiftyJSON
import PCL_Mac
import PCL_Mac_Core

struct ThemeParseTest {
    @Test func testGradientParsing() throws {
        let url = SharedConstants.shared.applicationResourcesUrl.appending(path: "pcl.json")
        let data = try FileHandle(forReadingFrom: url).readToEnd()!
        let json = try JSON(data: data)
        
        assert(ThemeParser.shared.parseGradient(json["titleStyle"]) != nil)
        assert(ThemeParser.shared.parseGradient(json["backgroundStyle"]) != nil)
    }
}
