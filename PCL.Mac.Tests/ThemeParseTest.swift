//
//  ThemeParseTest.swift
//  PCL.Mac
//
//  Created by YiZhiMCQiu on 8/5/25.
//

import Testing
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
}
