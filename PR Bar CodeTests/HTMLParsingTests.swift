//
//  HTMLParsingTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
@testable import PR_Bar_Code

struct HTMLParsingTests {
    
    @Test("Parkrun ID validation regex")
    func testParkrunIDValidation() {
        let validIDs = ["A12345", "A1", "A999999", "A123"]
        let invalidIDs = ["12345", "a12345", "B12345", "A", "AA12345", "", "A12345B"]
        
        let regex = #"^A\d+$"#
        
        for validID in validIDs {
            #expect(validID.range(of: regex, options: .regularExpression) != nil, "Valid ID \(validID) should match regex")
        }
        
        for invalidID in invalidIDs {
            #expect(invalidID.range(of: regex, options: .regularExpression) == nil, "Invalid ID \(invalidID) should not match regex")
        }
    }
    
    @Test("Name extraction regex pattern")
    func testNameExtractionRegex() throws {
        let testHTML = """
        <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
        """
        
        let pattern = #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let nameRange = Range(match.range(at: 1), in: testHTML) {
            let extractedName = String(testHTML[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(extractedName == "Matt GARDNER")
        }
    }
    
    @Test("Total parkruns extraction regex")
    func testTotalParkrunsRegex() throws {
        let testHTML = """
        <h3>279 parkruns total</h3>
        """
        
        let pattern = #"(\d+)\s+parkruns?\s+total"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let totalRange = Range(match.range(at: 1), in: testHTML) {
            let extractedTotal = String(testHTML[totalRange])
            #expect(extractedTotal == "279")
        }
    }
    
    @Test("Date extraction regex")
    func testDateExtractionRegex() throws {
        let testHTML = """
        <td>14/06/2025</td>
        """
        
        let pattern = #"(\d{2}/\d{2}/\d{4})"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: []))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let dateRange = Range(match.range(at: 1), in: testHTML) {
            let extractedDate = String(testHTML[dateRange])
            #expect(extractedDate == "14/06/2025")
        }
    }
    
    @Test("Time extraction regex")
    func testTimeExtractionRegex() throws {
        let testHTML = """
        <td>22:30</td>
        """
        
        let pattern = #"<td>(\d{2}:\d{2})</td>"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: []))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let timeRange = Range(match.range(at: 1), in: testHTML) {
            let extractedTime = String(testHTML[timeRange])
            #expect(extractedTime == "22:30")
        }
    }
    
    @Test("Event name extraction regex")
    func testEventNameExtractionRegex() throws {
        let testHTML = """
        <td><a href="/whiteley/results/671/">Whiteley parkrun</a></td>
        """
        
        let pattern = #"<td><a[^>]*>([^<]+parkrun[^<]*)</a></td>"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let eventRange = Range(match.range(at: 1), in: testHTML) {
            let extractedEvent = String(testHTML[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(extractedEvent == "Whiteley parkrun")
        }
    }
    
    @Test("Event URL extraction regex")
    func testEventURLExtractionRegex() throws {
        let testHTML = """
        <td><a href="https://www.parkrun.org.uk/whiteley/results/671/">14/06/2025</a></td>
        """
        
        let pattern = #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a></td>"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let urlRange = Range(match.range(at: 1), in: testHTML) {
            let extractedURL = String(testHTML[urlRange])
            #expect(extractedURL == "https://www.parkrun.org.uk/whiteley/results/671/")
        }
    }
    
    @Test("Complex HTML parsing integration")
    func testComplexHTMLParsing() throws {
        let complexHTML = """
        <html>
        <body>
        <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
        <h3>279 parkruns total</h3>
        <table>
        <tr>
        <td><a href="/whiteley/results/671/">Whiteley parkrun</a></td>
        <td><a href="https://www.parkrun.org.uk/whiteley/results/671/">14/06/2025</a></td>
        <td>22:30</td>
        </tr>
        </table>
        </body>
        </html>
        """
        
        // Test that all patterns can extract from the same HTML
        let namePattern = #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#
        let nameRegex = try #require(try? NSRegularExpression(pattern: namePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]))
        let nameMatches = nameRegex.matches(in: complexHTML, options: [], range: NSRange(complexHTML.startIndex..., in: complexHTML))
        #expect(nameMatches.count == 1)
        
        let totalPattern = #"(\d+)\s+parkruns?\s+total"#
        let totalRegex = try #require(try? NSRegularExpression(pattern: totalPattern, options: [.caseInsensitive]))
        let totalMatches = totalRegex.matches(in: complexHTML, options: [], range: NSRange(complexHTML.startIndex..., in: complexHTML))
        #expect(totalMatches.count == 1)
        
        let datePattern = #"(\d{2}/\d{2}/\d{4})"#
        let dateRegex = try #require(try? NSRegularExpression(pattern: datePattern, options: []))
        let dateMatches = dateRegex.matches(in: complexHTML, options: [], range: NSRange(complexHTML.startIndex..., in: complexHTML))
        #expect(dateMatches.count == 1)
        
        let timePattern = #"<td>(\d{2}:\d{2})</td>"#
        let timeRegex = try #require(try? NSRegularExpression(pattern: timePattern, options: []))
        let timeMatches = timeRegex.matches(in: complexHTML, options: [], range: NSRange(complexHTML.startIndex..., in: complexHTML))
        #expect(timeMatches.count == 1)
    }
    
    @Test("Edge case handling - empty or malformed HTML")
    func testEdgeCaseHandling() throws {
        let emptyHTML = ""
        let malformedHTML = "<h2>Incomplete"
        
        let pattern = #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]))
        
        // Empty HTML should return no matches
        let emptyMatches = regex.matches(in: emptyHTML, options: [], range: NSRange(emptyHTML.startIndex..., in: emptyHTML))
        #expect(emptyMatches.count == 0)
        
        // Malformed HTML should return no matches
        let malformedMatches = regex.matches(in: malformedHTML, options: [], range: NSRange(malformedHTML.startIndex..., in: malformedHTML))
        #expect(malformedMatches.count == 0)
    }
    
    @Test("URL generation for parkrun profile")
    func testParkrunProfileURLGeneration() {
        let parkrunID = "A79156"
        let numericId = String(parkrunID.dropFirst()) // Remove 'A' prefix
        let profileURL = "https://www.parkrun.org.uk/parkrunner/\(numericId)/all/"
        
        #expect(numericId == "79156")
        #expect(profileURL == "https://www.parkrun.org.uk/parkrunner/79156/all/")
        
        // Test URL validity
        let url = URL(string: profileURL)
        #expect(url != nil)
        #expect(url?.absoluteString == profileURL)
    }
}