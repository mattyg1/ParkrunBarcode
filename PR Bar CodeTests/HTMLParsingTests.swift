//
//  HTMLParsingTests.swift
//  PR Bar CodeTests
//
//  Created by Claude Code on 15/06/2025.
//

import Testing
import Foundation
@testable import FiveKQRCode

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
        <h3>50 parkruns & 1 junior parkrun total</h3>
        """
        
        let pattern = #"(\d+)\s+parkruns?(?:\s+&\s+\d+\s+junior\s+parkrun)?\s+total"#
        let regex = try #require(try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
        
        let matches = regex.matches(in: testHTML, options: [], range: NSRange(testHTML.startIndex..., in: testHTML))
        
        #expect(matches.count == 1)
        
        if let match = matches.first, let totalRange = Range(match.range(at: 1), in: testHTML) {
            let extractedTotal = String(testHTML[totalRange])
            #expect(extractedTotal == "50")
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
    
    @Test("Mia Gardner HTML parsing")
    func testMiaHTMLParsing() throws {
        let miaHTML = """
        <!DOCTYPE html>
        <html lang="en-US">
        <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="apple-touch-icon" sizes="180x180" href="/wp-content/themes/parkrun/favicons/apple-touch-icon.png">
        <link rel="icon" type="image/png" sizes="32x32" href="/wp-content/themes/parkrun/favicons/favicon-32x32.png">
        <link rel="icon" type="image/png" sizes="16x16" href="/wp-content/themes/parkrun/favicons/favicon-16x16.png">
        <link rel="manifest" href="/wp-content/themes/parkrun/favicons/site.webmanifest">
        <link rel="mask-icon" href="/wp-content/themes/parkrun/favicons/safari-pinned-tab.svg" color="#2b233d">
        <link rel="shortcut icon" href="/wp-content/themes/parkrun/favicons/favicon.ico">
        <meta name="msapplication-TileColor" content="#da532c">
        <meta name="msapplication-config" content="/wp-content/themes/parkrun/favicons/browserconfig.xml">
        <meta name="theme-color" content="#ffffff">
        <meta property="og:image" content="https://images.parkrun.com/website/general/5k_national.jpg" />
        <meta property="description" content="
        parkrun organise and provide free, weekly, 5k timed events around the world" />
        <title>results | parkrun UK</title>
        <link rel="profile" href="http://gmpg.org/xfn/11" />
        <!--[if lt IE 9]><script src="https://static.parkrun.com/wp-content/themes/twentyeleven/js/html5.js" type="text/javascript"></script><![endif]-->

        <link href='//fonts.googleapis.com/css?family=Montserrat:700,500,400,300&display=swap' rel='stylesheet' type='text/css' async defer>

        <meta name="robots" content="noindex"><link rel='dns-prefetch' href='//cdn.jsdelivr.net' />
        <link rel='dns-prefetch' href='//s.w.org' />
        <link rel="alternate" type="application/rss+xml" title="parkrun UK &raquo; Feed" href="https://www.parkrun.org.uk/feed/" />
        <link rel="alternate" type="application/rss+xml" title="parkrun UK &raquo; Comments Feed" href="https://www.parkrun.org.uk/comments/feed/" />
        <style type="text/css">
        img.wp-smiley,
        img.emoji {
        ddisplay: inline !important;
        border: none !important;
        box-shadow: none !important;
        height: 1em !important;
        width: 1em !important;
        margin: 0 .07em !important;
        vertical-align: -0.1em !important;
        background: none !important;
        padding: 0 !important;
        }
        </style>
        <link rel='stylesheet' id='style-css'  href='https://static.parkrun.com/wp-content/themes/parkrun/style.css?ver=1.25.1' type='text/css' media='all' />
        <link rel='stylesheet' id='swiper-css'  href='https://cdn.jsdelivr.net/npm/swiper/swiper-bundle.min.css?ver=1.25.1' type='text/css' media='all' />
        <link rel='stylesheet' id='iframemanager-css'  href='https://static.parkrun.com/wp-content/plugins/parkrun-cookies/dist/iframemanager.css?ver=1.0.1' type='text/css' media='all' />
        <link rel='stylesheet' id='cc-custom-style-css'  href='https://static.parkrun.com/wp-content/plugins/parkrun-cookies/psc.css?ver=1.0.1' type='text/css' media='all' />
        <link rel='stylesheet' id='twentyeleven-block-style-css'  href='https://static.parkrun.com/wp-content/themes/twentyeleven/blocks.css?ver=20240703' type='text/css' media='all' />
        <script type='text/javascript' src='https://static.parkrun.com/wp-includes/js/jquery/jquery.js?ver=1.12.4'></script>
        <script type='text/javascript' src='https://static.parkrun.com/wp-includes/js/jquery/jquery-migrate.min.js?ver=1.4.1'></script>
        <script type='text/javascript' src='https://cdn.jsdelivr.net/npm/swiper/swiper-bundle.min.js?ver=1.25.1'></script>
        <link rel='https://api.w.org/' href='https://www.parkrun.org.uk/wp-json/' />
        <link rel="EditURI" type="application/rsd+xml" title="RSD" href="https://www.parkrun.org.uk/xmlrpc.php?rsd" />
        <link rel="wlwmanifest" type="application/wlwmanifest+xml" href="https://static.parkrun.com/wp-includes/wlwmanifest.xml" /> 
        <link rel='shortlink' href='https://www.parkrun.org.uk/?p=297' />
        <link rel="alternate" type="application/json+oembed" href="https://www.parkrun.org.uk/wp-json/oembed/1.0/embed?url=https%3A%2F%2Fwww.parkrun.org.uk%2Fresults%2F" />
        <link rel="alternate" type="text/xml+oembed" href="https://www.parkrun.org.uk/wp-json/oembed/1.0/embed?url=https%3A%2F%2Fwww.parkrun.org.uk%2Fresults%2F&#038;format=xml" />

        </head>
        <body class="page-template-default page page-id-297 singular two-column right-sidebar">

        <t<!-- start of header -->
        <header id="mainheader" class="headerbar">
        <div class="headerbarleft">
        <a href="https://www.parkrun.org.uk" title="visit national site">
        <div class="headerbarprlogo" style= " background-image:url('https://images.parkrun.com/website/uk/prlogoC.svg'); "  > &#160; </div>
        </a>
        </div>
        <div class="headerbarright">
        <a href="https://donate.parkrun.com" class="button" id="donateButton">
        donate
        </a>    <div class="menubar">
        <div class="menuScrim"></div>
        <div class="menuButton">
        <div class="line"></div>
        <div class="line"></div>
        <div class="line"></div>
        </div>
        <nav id="access" role="navigation">
        <div class="menu-parkrun_country_menu_2024-05-10a-container"><ul id="menu-parkrun_country_menu_2024-05-10a" class="menu"><li id="menu-item-12804" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-has-children menu-item-12804"><a href="https://www.parkrun.org.uk/events/">events</a>
        <ul class="sub-menu">
        <li id="menu-item-12805" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12805"><a href="https://www.parkrun.org.uk/events/events/">parkrun events</a></li>
        <li id="menu-item-12806" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12806"><a href="https://www.parkrun.org.uk/events/juniorevents/">junior events</a></li>
        <li id="menu-item-12807" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12807"><a href="https://www.parkrun.org.uk/cancellations/">cancellations</a></li>
        <li id="menu-item-12808" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12808"><a href="https://www.parkrun.org.uk/special-events/">additional parkrun days</a></li>
        <li id="menu-item-12809" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12809"><a href="https://www.parkrun.org.uk/parkwalk/">parkwalk</a></li>
        </ul>
        </li>
        <li id="menu-item-12810" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12810"><a href="https://blog.parkrun.com/uk/">blog</a></li>
        <li id="menu-item-12811" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-has-children menu-item-12811"><a href="https://www.parkrun.org.uk/sponsors/">partners</a>
        <ul class="sub-menu">
        <li id="menu-item-12812" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12812"><a href="https://www.parkrun.org.uk/sponsors/vitality/">Vitality</a></li>
        <li id="menu-item-12813" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12813"><a href="https://www.parkrun.org.uk/sponsors/#coop">Co-op</a></li>
        <li id="menu-item-12814" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12814"><a href="https://www.parkrun.org.uk/sponsors/#brooks">Brooks</a></li>
        <li id="menu-item-12815" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12815"><a href="https://www.parkrun.org.uk/sponsors/#runna">Runna</a></li>
        <li id="menu-item-12816" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12816"><a href="https://www.parkrun.org.uk/sponsors/#sportsshoes">SportsShoes.com</a></li>
        <li id="menu-item-12817" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12817"><a href="https://www.parkrun.org.uk/sponsors/#kenco">Kenco</a></li>
        <li id="menu-item-12818" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-has-children menu-item-12818"><a href="https://www.parkrun.org.uk/charity-partners/">charity partners</a>
        <ul class="sub-menu">
        <li id="menu-item-12819" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12819"><a href="https://www.parkrun.org.uk/charity-partners/aruk/">Alzheimer's Research UK</a></li>
        <li id="menu-item-12820" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12820"><a href="https://www.parkrun.org.uk/charity-partners/macmillan/">Macmillan</a></li>
        <li id="menu-item-12821" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12821"><a href="https://www.parkrun.org.uk/charity-partners/wwf/">WWF</a></li>
        </ul>
        </li>
        <li id="menu-item-12822" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12822"><a href="https://www.parkrun.org.uk/sponsors/supporters/">supporters</a></li>
        <li id="menu-item-12823" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12823"><a href="https://www.parkrun.org.uk/sponsors/friends/">friends of</a></li>
        </ul>
        </li>
        <li id="menu-item-12824" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-has-children menu-item-12824"><a href="https://www.parkrun.com/about/support-us/">support us</a>
        <ul class="sub-menu">
        <li id="menu-item-12825" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12825"><a href="https://www.parkrun.com/about/support-us/ways-to-give/">ways to give</a></li>
        <li id="menu-item-12826" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12826"><a href="https://www.parkrun.com/about/support-us/the-difference-we-make/">the difference we make</a></li>
        <li id="menu-item-12827" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12827"><a href="https://www.parkrun.com/about/support-us/partners-and-sponsorship/">partners and sponsorship</a></li>
        <li id="menu-item-12828" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12828"><a href="https://www.parkrun.com/about/support-us/where-your-money-goes/">where your money goes</a></li>
        </ul>
        </li>
        <li id="menu-item-12829" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-has-children menu-item-12829"><a>results</a>
        <ul class="sub-menu">
        <li id="menu-item-12830" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12830"><a href="https://www.parkrun.org.uk/results/largestclubs/">largest clubs</a></li>
        <li id="menu-item-12831" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12831"><a href="https://www.parkrun.org.uk/results/historicalchart/">historical chart</a></li>
        <li id="menu-item-12832" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12832"><a href="https://www.parkrun.org.uk/results/notparkrun/">(not)parkrun</a></li>
        <li id="menu-item-12833" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12833"><a href="https://www.parkrun.org.uk/results/notparkrunhistory/">(not)parkrun history</a></li>
        </ul>
        </li>
        <li id="menu-item-12834" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12834"><a href="https://www.parkrun.org.uk/aboutus/">about us</a></li>
        <li id="menu-item-12835" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12835"><a href="https://shop.parkrun.com/">shop</a></li>
        <li id="menu-item-12836" class="menu-item menu-item-type-custom menu-item-object-custom menu-item-12836"><a href="https://www.parkrun.org.uk/register/">register</a></li>
        </ul></div>    </nav>
        </div>
        </div>
        </header>
        <div class="headerspacer"></div>
        <!--  end of header -->
        <main id="page" class="hfeed">

        <div id="main">

        <div id="primary">
        <div id="content" role="main">

        <a href='https://www.brooksrunning.com/en_gb/brooks-run-club/?tid=oth:parkrun:BrooksRunClub:pm1x:uk:parkrunhomepage'> 
        <picture class="parkrunadBanner">
        <source media='(min-width: 767px)' srcset='https://images.parkrun.com/blogs.dir/3/files/2025/03/parkrun-BRC-1100x100.jpg'>
        <img src='https://images.parkrun.com/blogs.dir/3/files/2025/03/767px-x-250px.jpg' 
        alt='Brooks Run Club' 
        style='width:auto;margin-bottom: 20px;'>
        </picture> 
        </a><?xml version="1.0"?>
        <h2>Mia GARDNER <span style="font-weight: normal;" title="parkrun ID">(A433032)</span></h2><a href="https://shop.parkrun.com/collections/run-walk-50" class="milestone-r50 Vanity-page--clubIcon Results-table--50club" title="Visit the parkrun shop">
                            Member of the parkrun 50 Club
                        </a><h3>50 parkruns & 1 junior parkrun total</h3><p><a href="https://www.parkrun.org.uk/parkrunner/433032/5k/">
                                    View stats for all 5k parkruns by this parkrunner
                                </a><br/><a href="https://www.parkrun.org.uk/parkrunner/433032/juniors/">
                                    View stats for all junior parkruns by this parkrunner
                                </a></p><p>
                                    Most recent age category was SW20-24
                                </p><div><h3 id="most-recent">Most Recent parkruns</h3><table class="sortable" id="results" cellspacing="4" cellpadding="0" align="center" border="0"><thead><tr><th>Event</th><th>Run Date</th><th>Gender<br />Pos</th><th>Overall Position</th><th>Time</th><th>Age<br/>Grade</th></tr></thead><tbody><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/326/" target="_top">31/05/2025</a></td><td>37</td><td>170</td><td>29:48</td><td>49.66%</td></tr><tr><td><a href="https://www.parkrun.org.uk/meonvalleytrailwickham/results/" target="_top">Meon Valley Trail parkrun, Wickham</a></td><td><a href="https://www.parkrun.org.uk/meonvalleytrailwickham/results/5/" target="_top">10/05/2025</a></td><td>65</td><td>212</td><td>30:50</td><td>48.00%</td></tr><tr><td><a href="https://www.parkrun.org.uk/fareham/results/" target="_top">Fareham parkrun</a></td><td><a href="https://www.parkrun.org.uk/fareham/results/406/" target="_top">08/03/2025</a></td><td>25</td><td>124</td><td>29:41</td><td>49.86%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/311/" target="_top">08/02/2025</a></td><td>36</td><td>190</td><td>29:56</td><td>49.44%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/309/" target="_top">25/01/2025</a></td><td>51</td><td>207</td><td>29:29</td><td>50.20%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/306/" target="_top">04/01/2025</a></td><td>29</td><td>167</td><td>29:23</td><td>50.37%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/305/" target="_top">28/12/2024</a></td><td>43</td><td>194</td><td>29:04</td><td>50.92%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/304/" target="_top">25/12/2024</a></td><td>18</td><td>110</td><td>28:32</td><td>51.87%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/302/" target="_top">14/12/2024</a></td><td>34</td><td>163</td><td>30:31</td><td>48.50%</td></tr><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/" target="_top">Whiteley parkrun</a></td><td><a href="https://www.parkrun.org.uk/whiteley/results/301/" target="_top">07/12/2024</a></td><td>36</td><td>158</td><td>30:05</td><td>49.20%</td></tr></tbody></table></div><br/><br/><div><h3 id="event-summary">Event Summaries</h3><table class="sortable" id="results" cellspacing="4" cellpadding="0" align="center" border="0"><thead><tr><th>Event</th><th>parkruns</th><th>Best Gender Position</th><th>Best Position Overall</th><th>Best Time</th><th class="unsortable"> </th><th class="unsortable"> </th></tr></thead><tbody><tr><td><a href="https://www.parkrun.org.uk/whiteley/results/">Whiteley parkrun</a></td><td>24</td><td>18</td><td>110</td><td><span class="pretty-time">28:32</span></td><td><a href="https://www.parkrun.org.uk/whiteley/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/whiteley/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/netleyabbey/results/">Netley Abbey parkrun</a></td><td>11</td><td>43</td><td>126</td><td><span class="pretty-time">39:29</span></td><td><a href="https://www.parkrun.org.uk/netleyabbey/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/netleyabbey/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/leeonthesolent/results/">Lee-on-the-Solent parkrun</a></td><td>4</td><td>55</td><td>229</td><td><span class="pretty-time">30:04</span></td><td><a href="https://www.parkrun.org.uk/leeonthesolent/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/leeonthesolent/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/fareham/results/">Fareham parkrun</a></td><td>4</td><td>25</td><td>105</td><td><span class="pretty-time">29:41</span></td><td><a href="https://www.parkrun.org.uk/fareham/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/fareham/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/portsmouthlakeside/results/">Portsmouth Lakeside parkrun</a></td><td>2</td><td>39</td><td>125</td><td><span class="pretty-time">31:14</span></td><td><a href="https://www.parkrun.org.uk/portsmouthlakeside/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/portsmouthlakeside/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/bartleypark/results/">Bartley Park parkrun</a></td><td>2</td><td>22</td><td>76</td><td><span class="pretty-time">32:09</span></td><td><a href="https://www.parkrun.org.uk/bartleypark/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/bartleypark/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/southsea/results/">Southsea parkrun</a></td><td>1</td><td>110</td><td>360</td><td><span class="pretty-time">32:08</span></td><td><a href="https://www.parkrun.org.uk/southsea/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/southsea/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/eastleigh/results/">Eastleigh parkrun</a></td><td>1</td><td>71</td><td>185</td><td><span class="pretty-time">35:34</span></td><td><a href="https://www.parkrun.org.uk/eastleigh/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/eastleigh/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/meonvalleytrailwickham/results/">Meon Valley Trail parkrun, Wickham</a></td><td>1</td><td>65</td><td>212</td><td><span class="pretty-time">30:50</span></td><td><a href="https://www.parkrun.org.uk/meonvalleytrailwickham/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/meonvalleytrailwickham/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr><tr><td><a href="https://www.parkrun.org.uk/southampton-juniors/results/">Southampton junior parkrun</a></td><td>1</td><td>20</td><td>48</td><td><span class="pretty-time">16:20</span></td><td><a href="https://www.parkrun.org.uk/southampton-juniors/parkrunner/433032/">
                                        All
                                    </a></td><td><a href="https://www.parkrun.org.uk/southampton-juniors/parkrunner/433032/chart/"><img border="0" alt="" src="https://images.parkrun.com/website/results/graph-it.png"/></a></td></tr></tbody><tfoot><tr><td style="text-align:right;padding-right:2px;font-variant:small-caps;">
                                        5k bests
                                    </td><td>50</td><td>18</td><td>76</td><td>28:32</td><td><a href="/parkrunner/433032/5k/">
                                        All
                                    </a></td><td>
                                     </td></tr><tr><td style="text-align:right;padding-right:2px;font-variant:small-caps;">
                                        junior bests
                                    </td><td>1</td><td>20</td><td>48</td><td>16:20</td><td><a href="/parkrunner/433032/juniors/">
                                        All
                                    </a></td><td>
                                     </td></tr></tfoot></table></div><br/><br/><div><h3 id="volunteer-summary">Volunteer Summary</h3><table class="sortable" id="results" cellspacing="4" cellpadding="0" align="center" border="0"><thead><tr><th>Role</th><th>Occasions</th></tr></thead><tbody><tr><td>
                                            Marshal
                                        </td><td>1</td></tr><tr><td>
                                            Pre-event Setup
                                        </td><td>1</td></tr><tr><td>
                                            Barcode Scanning
                                        </td><td>6</td></tr></tbody><tfoot><tr><td><strong>Total Credits</strong></td><td><strong>8</strong></td></tr></tfoot></table><p id="volunteer-summary-explain">
                    This table summarises the number of occasions that each volunteer role has been completed.<br>
        Please note that the total may differ from your total volunteer credits; if you have performed multiple tasks on the same day.<br>
        Find out more <a href='https://support.parkrun.com/hc/en-us/articles/200565303'>here</a>.</p></div><br/><br/>

        <div id="comments">
        </div><!-- #comments -->

        </div><!-- #content -->
        </div><!-- #primary -->

        <!-- extra clearing <br> - only *really* needed in news page, and not even
        there in practice as one of two columns (news and rhs sidebar) should stretch
        the page to fill the whole viewport height (which was the issue) - but works
        nicely on all pages - clears the bird on footer image fromt the text nicely -->
        <br class="clear" />

        </div><!-- #main -->
        </main>

        <footer role="contentinfo">
            <div id="footerStats">
                <div>


                    <div class="flex">
                        <div class="aStat">
                            Locations: <span class="num">861</span>
                        </div>
                        <div class="aStat">
                            Finishers: <span class="num">3,712,472</span>
                        </div>
                        <div class="aStat">
                            Finishes: <span class="num">65,447,010</span>
                        </div>
                        <div class="aStat">
                            All-time events: <span class="num">318,005</span>
                        </div>
                        <div class="aStat">
                            Volunteers: <span class="num">491,118</span>
                        </div>
                        <div class="aStat">
                            PBs: <span class="num">9,633,326</span>
                        </div>
                        <div class="aStat">
                            Average finish time: <span class="num">00:29:29</span>
                        </div>
                        <div class="aStat">
                            Groups: <span class="num">8,980</span>
                        </div>
                    </div>                     
                    <div class="lastupdated">
                        Stats last updated: Sun 15 Jun 2025 00:58:41 UTC
                    </div>
                </div>
            </div>
            <div id="footerLogos">
                <div>
                    <a href="/sponsors/vitality/" title="Vitality">
                        <img src="https://images.parkrun.com/website/sponsors/footer2020/vitality-products.svg" alt="Vitality">
                    </a>
                    <a href="https://www.coop.co.uk/health-wellbeing/parkrun" title="Co-Op">
                        <img src="https://images.parkrun.com/website/sponsors/footer2020/co-op.svg" alt="Co-Op">
                    </a>
                    <a href="https://www.brooksrunning.com/en_gb/parkrun/?utm_source=parkrun&amp;utm_medium=referral&amp;utm_campaign=uk%7Cbrand%7Cs20%7Cparkrun%7C-%7C-%7C-%7C-%7C-%7C-" title="Brooks">
                        <img src="https://images.parkrun.com/website/sponsors/footer2020/brooks.svg" alt="Brooks">
                    </a>
                    <a href="https://web.runna.com/redeem?code=PARKRUN" title="Runna">
                        <img src="https://images.parkrun.com/website/sponsors/footer2020/runna.svg" alt="Runna">
                    </a>
                    <a href="https://www.kenco.co.uk/parkrun" title="Kenco">
                        <img src="https://images.parkrun.com/website/sponsors/footer2020/kenco-hollow-wordmark.svg" alt="Kenco">
                    </a>
                </div>
            </div>
            <div id="footerLegal" class="footerOuter">
                <div id="legalLinks">
                    <a href='https://support.parkrun.com/'>Contact us</a>
                    <a href='http://www.parkrun.com/privacy/'>Privacy</a>
                    <a href='#cc-open-dialog'>Cookies</a>
                    <a href='/terms-conditions/'>Terms and Conditions</a>
                    <a href='https://safeguarding.parkrun.com/'>Safeguarding</a>
                    <a href='https://blog.parkrun.com/uk/tag/recruitment/'>Careers</a>
                </div>
                <p class="faded">&copy; parkrun Limited (Company Number: 07289574)</p>
                <p class="faded">No part of this site may be reproduced in whole or in part in any manner without the permission of the copyright owner.</p>
                <p>Frameworks, 2 Sheen Road, Richmond, TW9 1AE</p>
                <div id="footerSocial">
                    <div class="footerSocialLogo">
                        <a title="facebook" href="https://www.facebook.com/parkrunUK">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>Facebook</title><path fill="#FFFFFF" d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z"/></svg>
                        </a>
                    </div>
                    <div class="footerSocialLogo">
                        <a title="twitter" href="https://x.com/parkrunUK">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>X</title><path fill="#FFFFFF" d="M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z"/></svg>
                        </a>
                    </div>
                    <div class="footerSocialLogo">
                        <a title="instagram" href="https://instagram.com/parkrunuk">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title id="simpleicons-instagram-icon">Instagram</title><path fill="#FFFFFF" d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>
                        </a>
                    </div>
                    <div class="footerSocialLogo">
                        <a title="youtube" href="https://www.youtube.com/channel/UCtcIcjW5VMQdoqqcMGdrgkw">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title id="simpleicons-youtube-icon">YouTube</title><path fill="#FFFFFF" class="a" d="M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"/></svg>
                        </a>
                    </div>
                    <div class="footerSocialLogo">
                        <a title="tiktok" href="https://www.tiktok.com/@parkrun">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>TikTok</title><path fill="#FFFFFF" d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>
                        </a>
                    </div>
                    <div class="footerSocialLogo">
                        <a title="linkedin" href="https://uk.linkedin.com/company/parkrun">
                            <svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><title>LinkedIn</title><path fill="#FFFFFF" d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>
                        </a>
                    </div>
                </div>
            </div>
        </footer>
        <iframe height="0" id="iframe" src="https://www.parkrun.com/parkrun-smart-cookie/" width="0"></iframe><script type='text/javascript' src='https://static.parkrun.com/wp-content/themes/parkrun/scripts/parkrunTheme.js?ver=4.9.26'></script>
        <script type='text/javascript'>
        /* <![CDATA[ */
        var psc = {"settings":{"revision":1,"cookie":{"name":"psc","expiresAfterDays":"182"},"guiOptions":{"consentModal":{"layout":"bar inline","position":"bottom center","equalWeightButtons":true,"flipButtons":false},"preferencesModal":{"layout":"box","equalWeightButtons":true,"flipButtons":false}},"current_lang":"en","autoClearCookies":true,"disablePageInteraction":true,"page_scripts":true,"secondary_btn_role":"accept_necessary","language":{"default":"en","autoDetect":"document","translations":{"en":{"consentModal":{"title":"Cookies","description":"parkrun uses cookies to provide essential site functionality, improve your experience, and analyse website traffic.<br>To update your cookie preferences in the future, please click the 'Cookies' link in the website's footer.","acceptAllBtn":"Accept all","acceptNecessaryBtn":"Reject all","showPreferencesBtn":"Manage preferences"},"preferencesModal":{"title":"Cookie preferences","acceptAllBtn":"Accept all","acceptNecessaryBtn":"Reject all","savePreferencesBtn":"Save preferences","closeIconLabel":"Close","sections":[{"title":"Cookie usage","description":"parkrun uses cookies to provide essential site functionality, improve your experience, and analyse website traffic.<br>Third-party services like Mapbox and YouTube may also set cookies to deliver maps and embedded videos. <br><a href=\"https://parkrun.me/pp510\">More information is available on our privacy policy.</a>"},{"title":"Strictly necessary","description":"These cookies are essential for the proper functioning of this website and cannot be disabled.","linkedCategory":"necessary"},{"title":"Personalisation","description":"These cookies allow this website to remember the choices you have made in the past.","linkedCategory":"personalisation"},{"title":"Performance and Analytics","description":"These cookies help us understand how this website is used and improve user experience.","linkedCategory":"analytics"}]}},"categories":{"necessary":{"enabled":true,"readOnly":true,"cookies":[]},"personalisation":{"enabled":false,"readOnly":false,"autoClear":{"cookies":["parkrun-results-table-display-preference"],"reloadPage":false}},"analytics":{"enabled":false,"readOnly":false,"autoClear":{"cookies":["/_ga","_gid","im_youtube"],"reloadPage":true},"services":{"ga":{"label":"Google Analytics","cookies":["/_ga","_gid"],"languages":[]},"mapbox":{"label":"Mapbox","languages":[]},"youtube":{"label":"YouTube","cookies":["VISITOR_INFO1_LIVE","VISITOR_PRIVACY_METADATA","YSC"],"embedUrl":"https://www.youtube-nocookie.com/embed/{data-id}","thumbnailUrl":"https://img.youtube.com/vi/{data-id}/hqdefault.jpg","iframe":{"allow":"accelerometer; encrypted-media; gyroscope; picture-in-picture; fullscreen;"},"languages":{"en":{"notice":"Third-party services like Mapbox and YouTube may also set cookies to deliver maps and embedded videos. ","loadBtn":"Load video","loadAllBtn":"Don't ask again"}},"twitter":{"label":"X (Twitter)","cookies":[],"languages":[]}}}};
        /* ]]> */
        </script>
        <script type='text/javascript' src='https://static.parkrun.com/wp-content/plugins/parkrun-cookies/dist/cookieconsent.bundle.js?ver=1.0.1'></script>
        <script type='text/javascript' src='https://static.parkrun.com/wp-includes/js/wp-embed.min.js?ver=4.9.26'></script>
        <script type='text/javascript' src='https://cdn.jsdelivr.net/npm/feather-icons/dist/feather.min.js?ver=4.9.26'></script>
        <script type='text/javascript'>
        feather.replace({width: '1em', height: '1em'})
        </script>
        <script type='text/plain' data-category='analytics' data-service='ga' src='https://www.googletagmanager.com/gtag/js?id=G-MG7X4X82TB'></script>
        <script type='text/plain' data-category='analytics' data-service='ga'>
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}\
                gtag('js', new Date());
                gtag('config', 'G-MG7X4X82TB');
        </script>
        <script type='text/javascript' src='https://static.parkrun.com/wp-content/plugins/parkrun/includes/../scripts/sortable.js?ver=4.9.26'></script>
        <script type='text/javascript'>
        /* <![CDATA[ */
        var site_type = "c";
        /* ]]> */
        </script>
        <script type='text/javascript' src='https://static.parkrun.com/wp-content/plugins/parkrun-cookies/psc_sync.js?ver=1.0.1'></script>
        <script id="ze-snippet" type='text/javascript' src='https://static.zdassets.com/ekr/snippet.js?key=b7889cc3-92bf-4e40-9822-a91e6381a1ed'></script>
        <script type='text/javascript'>
        window.zESettings={webWidget:{color:{theme:"#ffa300"}}};
        </script>

        </body>
        </html>

        <!-- Dynamic page generated in 0.950 seconds. -->
        <!-- Cached page generated by WP-Super-Cache on 2025-06-15 18:44:38 -->

        <!-- Compression = gzip -->
        """

        let familyTabViewInstance = FamilyTabView()
        let extractedData = familyTabViewInstance.extractParkrunnerDataFromHTML(miaHTML)

        #expect(extractedData.name == "Mia GARDNER")
        #expect(extractedData.totalRuns == "50")
        #expect(extractedData.lastDate == "31/05/2025")
        #expect(extractedData.lastTime == "29:48")
        #expect(extractedData.lastEvent == "Whiteley parkrun")
        #expect(extractedData.lastEventURL == "https://www.parkrun.org.uk/whiteley/results/326/")
    }

    @Test("Matt Gardner HTML parsing")
    func testMattHTMLParsing() throws {
        let mattHTML = """
        <!DOCTYPE html>
        <html lang="en-US">
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>results | parkrun UK</title>
        </head>
        <body>
            <h2>Matt GARDNER <span style="font-weight: normal;" title="parkrun ID">(A79156)</span></h2>
            <h3>279 parkruns total</h3>
            <div>
                <h3 id="most-recent">Most Recent parkruns</h3>
                <table class="sortable" id="results" cellspacing="4" cellpadding="0" align="center" border="0">
                    <thead>
                        <tr>
                            <th>Event</th>
                            <th>Date</th>
                            <th>Pos</th>
                            <th>Time</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><a href="/parkrun/whiteley/results/326/">Whiteley parkrun</a></td>
                            <td>31/05/2025</td>
                            <td>1</td>
                            <td>16:20</td>
                        </tr>
                        <tr>
                            <td><a href="/parkrun/whiteley/results/325/">Whiteley parkrun</a></td>
                            <td>24/05/2025</td>
                            <td>1</td>
                            <td>16:15</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </body>
        </html>
        """

        let familyTabViewInstance = FamilyTabView()
        let extractedData = familyTabViewInstance.extractParkrunnerDataFromHTML(mattHTML)

        #expect(extractedData.name == "Matt GARDNER")
        #expect(extractedData.totalRuns == "279")
        #expect(extractedData.lastDate == "31/05/2025")
        #expect(extractedData.lastTime == "16:20")
        #expect(extractedData.lastEvent == "Whiteley parkrun")
        #expect(extractedData.lastEventURL == "https://www.parkrun.org.uk/gangerfarm/results/133/")
    }
}
