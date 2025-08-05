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

struct ThemeParseTest {
    @Test func testColorParsing() {
        assert(ThemeParser.shared.parseColor("#00FF00") != nil)
        assert(ThemeParser.shared.parseColor("#8C00FF00") != nil)
        assert(ThemeParser.shared.parseColor("#800FF00") == nil)
        assert(ThemeParser.shared.parseColor("hsl(195,68,8)") != nil)
        assert(ThemeParser.shared.parseColor("hsl(195, 68,8)") != nil)
        assert(ThemeParser.shared.parseColor("hsl(195, 68 , 8)") != nil)
    }
    
    @Test func testGradientParsing() throws {
        let url = SharedConstants.shared.applicationResourcesUrl.appending(path: "pcl.json")
        let data = try FileHandle(forReadingFrom: url).readToEnd()!
        let json = try JSON(data: data)
        
        assert(ThemeParser.shared.parseGradient(json["titleStyle"]) != nil)
        assert(ThemeParser.shared.parseGradient(json["backgroundStyle"]) != nil)
    }
}
