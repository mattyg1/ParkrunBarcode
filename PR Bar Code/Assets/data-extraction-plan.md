# parkrun Data Extraction Strategy - Comprehensive Plan

## Problem Analysis

### Current Limitation
- **Limited Data Source**: Currently only fetching from `/parkrunner/79156/` (summary page)
- **Truncated Dataset**: Summary page only shows ~20 most recent runs 
- **Insufficient for Visualizations**: Performance timeline and activity heatmap need complete historical data
- **Missing Details**: Age grading, position data, PB indicators not fully captured

### Available Data Sources

#### 1. Summary Page: `/parkrunner/79156/`
**Contains:**
- Basic user info (name, ID, milestone badges)
- Total runs count
- Recent ~20 runs only
- Limited detail per run

**Good for:**
- User identification
- Basic stats
- Recent activity overview

#### 2. Complete Results Page: `/parkrunner/79156/all/`
**Contains:**
- **ALL 283 parkruns** with complete history
- Full run details: Event, Date, Run Number, Position, Time, Age Grade, PB indicator
- Annual achievement summaries
- Summary statistics (fastest, average, slowest)

**Perfect for:**
- Performance timeline charts (complete historical data)
- Activity heatmap (all dates for yearly analysis)
- Venue distribution analysis
- Personal best tracking
- Long-term performance trends

## Data Extraction Strategy

### Phase 1: Dual-Source Data Collection

#### Primary Data Source (Summary Page)
- **URL**: `https://www.parkrun.org.uk/parkrunner/{id}/`
- **Purpose**: Basic user info, validation, recent activity
- **When to use**: Initial user setup, quick refreshes
- **Data extracted**: Name, total runs, milestone status, recent runs

#### Secondary Data Source (Complete Results)
- **URL**: `https://www.parkrun.org.uk/parkrunner/{id}/all/`
- **Purpose**: Comprehensive visualization data
- **When to use**: Full data refresh, visualization updates
- **Data extracted**: Complete run history, performance trends, venue analysis

### Phase 2: Enhanced Data Models

#### Extend VenueRecord Model
```swift
@Model
class VenueRecord {
    var venue: String
    var date: String
    var time: String
    var runNumber: Int?        // NEW: Event run number
    var position: Int?         // NEW: Overall position
    var ageGrading: Double?    // NEW: Age grading percentage
    var isPB: Bool = false     // NEW: Personal best indicator
    var eventURL: String?
    var parkrunInfo: ParkrunInfo?
}
```

#### Add Annual Performance Model
```swift
@Model
class AnnualPerformance {
    var year: Int
    var bestTime: String
    var bestAgeGrading: Double
    var totalRuns: Int
    var parkrunInfo: ParkrunInfo?
}
```

### Phase 3: Enhanced HTML Parsing

#### Complete Results Page Parser
- **Target table**: `<table class="sortable" id="results">` with caption "All Results"
- **Row pattern**: Extract Event, Run Date, Run Number, Position, Time, Age Grade, PB indicator
- **Annual summary**: Extract yearly achievements table
- **Statistics**: Overall fastest/average/slowest times

#### Parsing Strategy
1. **Sequential parsing**: Summary page first, then complete data
2. **Differential updates**: Only fetch complete data when needed
3. **Data validation**: Cross-reference summary vs complete data
4. **Error handling**: Graceful fallback to summary data if complete data fails

### Phase 4: Visualization Data Enhancement

#### Performance Timeline Chart
- **Current**: Limited to ~10 recent runs
- **Enhanced**: Full historical data with configurable time windows
- **New features**: 
  - Yearly/monthly aggregation views
  - Age grading trends
  - Position trends
  - Long-term performance patterns

#### Activity Heatmap
- **Current**: Limited recent data
- **Enhanced**: Complete yearly activity patterns
- **New features**:
  - Multi-year heatmaps
  - Run frequency patterns
  - Seasonal activity analysis
  - Venue diversity over time

#### Venue Analysis
- **Enhanced data**: Complete venue history for accurate statistics
- **Better insights**: Venue progression, performance by venue, geographic spread

### Phase 5: Implementation Plan

#### Step 1: Data Model Extensions
- Extend VenueRecord with new fields
- Add AnnualPerformance model
- Update ParkrunInfo relationships

#### Step 2: Enhanced Parsing Functions
- `extractCompleteResultsFromHTML()` - Parse complete results table
- `extractAnnualSummaryFromHTML()` - Parse yearly achievements
- `extractOverallStatsFromHTML()` - Parse summary statistics

#### Step 3: Dual-Source Data Fetching
- `fetchBasicParkrunData()` - Summary page for basic info
- `fetchCompleteResultsData()` - Complete results for visualizations
- `updateCompleteVisualizationData()` - Orchestrate both sources

#### Step 4: Smart Data Management
- **Incremental updates**: Only fetch complete data when needed
- **Caching strategy**: Store complete data locally, refresh periodically
- **Performance optimization**: Background fetching, progress indicators

#### Step 5: Enhanced Visualizations
- Update existing charts to use richer data
- Add new visualization features leveraging complete dataset
- Implement configurable time windows and data views

## Expected Outcomes

### Immediate Benefits
- **Complete performance timeline**: All 283 runs for comprehensive trends
- **Accurate activity heatmap**: True yearly activity patterns
- **Enhanced venue analysis**: Statistics based on complete venue history
- **Richer insights**: Age grading trends, position analysis, PB tracking

### Technical Benefits
- **Robust data foundation**: Complete dataset for current and future visualizations
- **Scalable architecture**: Easy to add new chart types and analyses
- **Reliable data source**: Less dependency on limited summary page data

### User Experience
- **Comprehensive insights**: Full parkrun journey visualization
- **Historical analysis**: Track long-term progress and patterns
- **Rich details**: Age grading, position trends, personal achievement tracking

## Implementation Priority

1. **HIGH**: Dual-source data fetching architecture
2. **HIGH**: Complete results page parsing
3. **MEDIUM**: Enhanced data models and storage
4. **MEDIUM**: Updated visualization components
5. **LOW**: Advanced analytics and trend analysis

This plan addresses the core limitation of truncated data while building a foundation for comprehensive parkrun journey analysis.