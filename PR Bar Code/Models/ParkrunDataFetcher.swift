
//
//  ParkrunDataFetcher.swift
//  PR Bar Code
//
//  Created by Gemini on 08/07/2025.
//

import Foundation

public class ParkrunDataFetcher {
    public static let shared = ParkrunDataFetcher()
    private init() {}
    
    public func fetchParkrunnerData(for parkrunID: String, completion: @escaping ((name: String?, totalRuns: String?, lastDate: String?, lastTime: String?, lastEvent: String?, lastEventURL: String?)) -> Void) {
        let numericId = String(parkrunID.dropFirst())
        let urlString = "https://www.parkrun.org.uk/parkrunner/\(numericId)/"
        
        guard let url = URL(string: urlString) else {
            completion((nil, nil, nil, nil, nil, nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                completion((nil, nil, nil, nil, nil, nil))
                return
            }
            
            let extractedData = self.extractParkrunnerDataFromHTML(htmlString)
            DispatchQueue.main.async {
                completion(extractedData)
            }
        }.resume()
    }
    
    public func extractParkrunnerDataFromHTML(_ html: String) -> (name: String?, totalRuns: String?, lastDate: String?, lastTime: String?, lastEvent: String?, lastEventURL: String?) {
        var name: String?
        var totalRuns: String?
        var lastDate: String?
        var lastTime: String?
        var lastEvent: String?
        var lastEventURL: String?
        
        let namePattern = #"<h2>([^<]+?)\s*<span[^>]*title="parkrun ID"[^>]*>"#
        if let nameRegex = try? NSRegularExpression(pattern: namePattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let nameMatches = nameRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = nameMatches.first, let nameRange = Range(match.range(at: 1), in: html) {
                name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        let totalPattern = #"(\d+)\s+parkruns?(?:\s+&\s+\d+\s+junior\s+parkrun)?\s+total"#
        if let totalRegex = try? NSRegularExpression(pattern: totalPattern, options: [.caseInsensitive]) {
            let totalMatches = totalRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = totalMatches.first, let totalRange = Range(match.range(at: 1), in: html) {
                totalRuns = String(html[totalRange])
            }
        }
        
        let eventPattern = #"<td><a[^>]*>([^<]+parkrun[^<]*)</a></td>"#
        if let eventRegex = try? NSRegularExpression(pattern: eventPattern, options: [.caseInsensitive]) {
            let eventMatches = eventRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = eventMatches.first, let eventRange = Range(match.range(at: 1), in: html) {
                lastEvent = String(html[eventRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        let datePattern = #"(\d{2}/\d{2}/\d{4})"#
        if let dateRegex = try? NSRegularExpression(pattern: datePattern, options: []) {
            let dateMatches = dateRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = dateMatches.first, let dateRange = Range(match.range(at: 1), in: html) {
                lastDate = String(html[dateRange])
            }
        }
        
        let timePattern = #"<td>(\d{2}:\d{2})</td>"#
        if let timeRegex = try? NSRegularExpression(pattern: timePattern, options: []) {
            let timeMatches = timeRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = timeMatches.first, let timeRange = Range(match.range(at: 1), in: html) {
                lastTime = String(html[timeRange])
            }
        }
        
        let eventURLPattern = #"<td><a href="(https://www\.parkrun\.(?:org\.uk|com|us|au|org\.nz|co\.za|it|se|dk|pl|ie|ca|fi|fr|sg|de|no|ru|my)/[^/]+/results/\d+/)"[^>]*>\d{2}/\d{2}/\d{4}</a></td>"#
        if let eventURLRegex = try? NSRegularExpression(pattern: eventURLPattern, options: [.caseInsensitive]) {
            let urlMatches = eventURLRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            if let match = urlMatches.first, let urlRange = Range(match.range(at: 1), in: html) {
                lastEventURL = String(html[urlRange])
            }
        }
        
        return (name, totalRuns, lastDate, lastTime, lastEvent, lastEventURL)
    }
}
