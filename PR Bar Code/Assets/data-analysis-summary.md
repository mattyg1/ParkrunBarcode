# Data Analysis Summary & Recommendations

## Current Data Source Analysis

### Summary Page (`/parkrunner/79156/`)
- **Purpose**: Basic user information and recent activity
- **Contains**: ~20 most recent runs, basic user stats
- **Limitations**: Insufficient for comprehensive visualizations

### Complete Results Page (`/parkrunner/79156/all/`)
- **Contains**: ALL 283 parkruns with complete historical data
- **Rich Data Structure**:
  - Event name and links
  - Run dates (format: DD/MM/YYYY)
  - Run numbers for each event
  - Overall position in each run
  - Finish times
  - Age grading percentages
  - Personal Best (PB) indicators
  - Annual achievement summaries
  - Overall statistics (fastest/average/slowest)

## Data Structure Found in Complete Results

### 1. Summary Statistics Table
```html
<table id="results">
  <caption>Summary Stats for All Locations</caption>
  <thead><tr><th/><th>Fastest</th><th>Average</th><th>Slowest</th></tr></thead>
  <tbody>
    <tr><td>Time</td><td>21:03</td><td>24:47</td><td>49:24</td></tr>
    <tr><td>Age Grading</td><td>66.35%</td><td>58.16%</td><td>27.63%</td></tr>
    <tr><td>Overall Position</td><td>18</td><td>66.32</td><td>315</td></tr>
  </tbody>
</table>
```

### 2. Annual Achievements Table
```html
<table class="sortable" id="results">
  <caption>Best Overall Annual Achievements</caption>
  <thead><tr><th>Year</th><th>Best Time</th><th>Best Age Grading</th></tr></thead>
  <tbody>
    <tr><td>2025</td><td>00:24:08</td><td>62.09%</td></tr>
    <!-- 16 years of data from 2010-2025 -->
  </tbody>
</table>
```

### 3. Complete Results Table (283 entries)
```html
<table class="sortable" id="results">
  <caption>All Results</caption>
  <thead><tr><th>Event</th><th>Run Date</th><th>Run Number</th><th>Pos</th><th>Time</th><th>Age Grade</th><th>PB?</th></tr></thead>
  <tbody>
    <tr>
      <td><a href="...">Whiteley</a></td>
      <td><a href="..."><span class="format-date">05/07/2025</span></a></td>
      <td><a href="...">331</a></td>
      <td>57</td>
      <td>24:24</td>
      <td>61.41%</td>
      <td><!-- PB indicator if applicable --></td>
    </tr>
    <!-- 282 more entries with complete history -->
  </tbody>
</table>
```

## Visualization Requirements vs Available Data

### ✅ **Well Supported Visualizations**

#### 1. Performance Timeline Chart
- **Needs**: Historical time data with dates
- **Available**: All 283 runs with exact dates and times
- **Enhancement**: Can show complete 16-year progression, not just recent 10 runs

#### 2. Activity Heatmap
- **Needs**: Run dates for yearly activity patterns
- **Available**: Complete date history (2010-2025)
- **Enhancement**: True activity patterns, seasonal analysis, multi-year views

#### 3. Venue Distribution Chart
- **Needs**: Complete venue history for accurate statistics
- **Available**: All venues with complete run counts
- **Enhancement**: Accurate percentages based on full 283-run history

#### 4. Best Times by Venue Chart
- **Needs**: Performance data by venue
- **Available**: All times by venue, can calculate true personal bests
- **Enhancement**: Accurate venue-specific performance analysis

### 🔄 **Enhanced Visualization Opportunities**

#### 5. Age Grading Analysis (NEW)
- **Available**: Age grading for every run
- **Opportunity**: Track fitness progression independent of age

#### 6. Position Trends (NEW)
- **Available**: Overall position for every run
- **Opportunity**: Analyze competitive performance trends

#### 7. Personal Best Tracking (NEW)
- **Available**: PB indicators for every run
- **Opportunity**: Visualize PB progression over time

#### 8. Annual Performance Summary (NEW)
- **Available**: Yearly best times and age grading
- **Opportunity**: Year-over-year performance comparison

## Recommended Implementation Strategy

### Phase 1: Dual-Source Architecture
1. **Keep existing summary page parsing** for basic user info and quick updates
2. **Add complete results page parsing** for comprehensive visualization data
3. **Smart fetching logic**: Use summary for basic info, complete data for visualizations

### Phase 2: Enhanced Data Models
1. **Extend VenueRecord** with position, age grading, PB indicator
2. **Add AnnualPerformance model** for yearly summaries
3. **Add OverallStats model** for fastest/average/slowest tracking

### Phase 3: Parsing Strategy
1. **Target the complete results table** with caption "All Results"
2. **Extract annual achievements** from yearly summary table
3. **Parse overall statistics** from summary stats table

### Phase 4: Visualization Enhancements
1. **Performance Timeline**: Show configurable time windows (1 year, 5 years, all time)
2. **Activity Heatmap**: True yearly patterns with multi-year support
3. **New Charts**: Age grading trends, position analysis, PB progression

## Key Benefits

### Data Completeness
- **283 complete runs** vs current ~20 recent runs
- **16 years of history** for long-term trend analysis
- **Rich metadata**: positions, age grading, PB indicators

### Visualization Accuracy
- **True venue statistics** based on complete history
- **Accurate activity patterns** for heatmap visualization
- **Comprehensive performance timeline** showing full parkrun journey

### New Insights
- **Age-adjusted performance trends** through age grading
- **Competitive performance analysis** through position tracking
- **Achievement progression** through PB indicators
- **Yearly performance comparison** through annual summaries

This approach transforms the visualizations from "recent activity snapshots" to "comprehensive parkrun journey analysis".