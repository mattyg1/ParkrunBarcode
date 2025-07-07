# parkrun Data Visualizations Implementation Plan

## Overview
Implement comprehensive parkrun data visualizations under the Watch Sync card on the Me tab, based on the HTML prototype showing Matt Gardner's parkrun journey with 283 runs across 17 venues.

## Phase 1: Data Model & Structure Updates

### Extend ParkrunInfo Model
- Add fields for historical data storage
  - `venueHistory: [VenueRecord]` - all runs with venue, date, time
  - `volunteerRecords: [VolunteerRecord]` - volunteer occasions and roles
  - `personalBests: [VenueBest]` - best time at each venue
  - `geographicData: [String]` - regions/countries visited

### Create New Data Models
```swift
struct VenueRecord {
    let venue: String
    let date: String
    let time: String
    let eventURL: String?
}

struct VolunteerRecord {
    let role: String
    let venue: String
    let date: String
}

struct VenueBest {
    let venue: String
    let bestTime: String
    let date: String
}

struct VenueStats {
    let name: String
    let runCount: Int
    let bestTime: String
    let percentage: Double
}
```

## Phase 2: Enhanced Data Collection

### Expand HTML Parsing
- Extract full venue history from results table (not just recent)
- Parse volunteer credit section for role breakdown
- Capture geographic/regional information from venue names
- Calculate running statistics and milestones

### New Parsing Functions
- `extractVenueHistory()` - parse complete results table
- `extractVolunteerData()` - parse volunteer credits section
- `calculatePersonalBests()` - find best time at each venue
- `analyzeGeographicSpread()` - group venues by region

## Phase 3: SwiftUI Chart Components

### Chart Views (using SwiftUI Charts framework)
1. **VenueDistributionChart**: Donut chart showing venue breakdown
   - Most frequented venues with percentages
   - Color-coded by run frequency

2. **PerformanceTimelineChart**: Line chart of recent performance
   - Last 10-15 runs with trend analysis
   - Venue context on data points

3. **BestTimesByVenueChart**: Bar chart of personal bests
   - Top 10 venues by best time performance
   - Color gradients for sub-22, sub-23, etc.

4. **ActivityHeatmapView**: Custom grid view for yearly activity
   - Calendar-style heatmap showing run frequency
   - Similar to GitHub contribution graph

5. **VolunteerContributionChart**: Polar area chart for volunteer roles
   - Breakdown by role type (Marshal, Timekeeper, etc.)
   - Show community contribution beyond running

6. **GeographicSpreadChart**: Radar chart for regional distribution
   - Hampshire/South Coast, International, etc.
   - Show parkrun tourism patterns

### Statistics Summary Cards
Match the 5-card layout from HTML prototype:
- Total parkruns (283)
- Best time (21:03)
- Venues visited (17)
- Volunteer credits (14)
- Milestone badges (250 Club Member ✓)

## Phase 4: Integration into MeTabView

### Add Visualizations Section
Insert new section after Watch Sync card:
```swift
// parkrun Journey Visualizations
VStack(alignment: .leading, spacing: 12) {
    Text("parkrun Journey")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.adaptiveParkrunGreen)
    
    parkrunVisualizationsSection
}
.cardStyle()
```

### Navigation & Interaction
- Collapsible sections for each chart category
- Tap gestures for detailed chart views
- Chart selection highlighting and tooltips
- Integration with existing data refresh flow

## Phase 5: Visual Design & Styling

### Color Scheme
Use consistent parkrun green theme:
- Primary: `#667eea` (parkrun blue-purple)
- Secondary: `#764ba2` (deeper purple)
- Accent gradients matching HTML prototype
- Maintain accessibility contrast ratios

### Responsive Layout
- Adaptive card sizing for iPhone/iPad
- Chart height optimization for mobile viewing
- Horizontal scrolling for wide charts if needed
- Dark mode compatibility

## Phase 6: Data Persistence & Performance

### Caching Strategy
- Store processed visualization data in SwiftData
- Separate model for historical data (`ParkrunVisualizationData`)
- Background processing for heavy calculations

### Performance Optimization
- Lazy loading of chart components
- Chart data sampling for large datasets
- Skeleton/shimmer loading states
- Debounced data refresh to avoid excessive API calls

## Implementation Approach

### Technical Stack
- **SwiftUI Charts** (iOS 16+) for native chart performance
- **Custom Canvas** for heatmap visualization (D3.js equivalent)
- **SwiftData** for local data persistence
- **Async/await** for background data processing

### Development Phases
1. **Data Layer**: Extend models and parsing logic
2. **Chart Components**: Build individual chart views
3. **Integration**: Add to MeTabView with proper layout
4. **Polish**: Animations, interactions, accessibility
5. **Testing**: Verify with real parkrun data

### Progressive Enhancement
- Start with basic charts using mock data
- Add real data integration
- Implement interactions and animations
- Add advanced features (export, sharing)

## Expected Result

A comprehensive "parkrun Journey" section displaying:
- **Overview Cards**: Key statistics at a glance
- **Venue Analysis**: Distribution and personal bests
- **Performance Tracking**: Timeline and trends
- **Activity Patterns**: Yearly heatmap
- **Community Contribution**: Volunteer breakdown
- **Geographic Exploration**: Regional spread

All seamlessly integrated below the Watch Sync card, providing rich insights into the user's parkrun journey while maintaining the app's existing design language and performance standards.

## Files to Modify
- `ParkrunInfo.swift` - extend data model
- `MeTabView.swift` - add visualization section
- Create new chart component files in Views folder
- Update HTML parsing functions for historical data
- Add chart styling and color definitions

## Dependencies
- SwiftUI Charts framework (iOS 16+)
- No external chart libraries needed
- Leverage existing SwiftData and networking infrastructure