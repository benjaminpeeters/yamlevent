# yamlevent

A command-line tool for managing YAML event entries.

## Features

- **Create new events** with metadata (date, ISO country code, title) and content arrays
- **Add content** to existing events with detailed source validation  
- **Comprehensive source validation** supporting URLs, local files, and mixed sources
- **List field support** with pipe separator for multiple items
- **Flexible date formats** including years, quarters, and date ranges
- **Robust error handling** and validation

## Installation

### Option 1: Direct Installation
```bash
# Copy to your PATH
cp yamlevent ~/bin/
# or
sudo cp yamlevent /usr/local/bin/

# Make executable
chmod +x ~/bin/yamlevent  # or /usr/local/bin/yamlevent
```

### Option 2: From Source
```bash
git clone https://github.com/benjaminpeeters/yamlevent.git
cd yamlevent
chmod +x yamlevent
ln -s "$(pwd)/yamlevent" ~/bin/yamlevent
```

## Usage

### Create New Event
```bash
yamlevent --new <file> <line> <iso> <date> <title> --description DESC --source SOURCE
```

### Add Content to Existing Event
```bash
yamlevent --add <file> <label> --description DESC --source SOURCE
```

### Help
```bash
yamlevent --help
yamlevent --version
```

## Examples

### Creating a New Event
```bash
yamlevent --new events.md 10 USA 1929-10 "Stock Market Crash" \
  --description "Black Tuesday triggers financial crisis|Market loses 25% in single day" \
  --cause "Excessive speculation|Margin buying overextension|Overvalued stocks" \
  --impact "Wealth destruction|Investor confidence collapses|Credit tightens" \
  --demo "Shows market psychology effects|Demonstrates leverage dangers" \
  --source "Federal Reserve|url:https://fraser.stlouisfed.org|url:https://federalreservehistory.org"
```

### Adding Content to Existing Event
```bash
yamlevent --add events.md "usa_1929_10_stock_market_crash" \
  --description "Banking system collapses|Bank runs spread nationwide|Rural banks fail first" \
  --cause "Overleveraged institutions|Loss of public confidence|Agricultural debt crisis" \
  --impact "9,000 banks fail by 1933|Savings accounts wiped out|Credit system breaks" \
  --demo "Shows banking interconnectedness|Reveals deposit insurance need" \
  --source "FDIC Historical Archives|path:~/research/bank_failures_1929.txt"
```

## Argument Reference

### Required Arguments

#### New Event Mode (`--new`)
- `<file>`: Target .md or .yml file
- `<line>`: Line number for insertion (1-based)
- `<iso>`: 3-letter country code (USA, GBR, CHE, etc.)
- `<date>`: Event date (see date formats below)
- `<title>`: Event title (converted to underscore_separated_label)
- `--description`: Event description (MANDATORY)
- `--source`: Source specification (MANDATORY, can repeat)

#### Add Content Mode (`--add`)
- `<file>`: Target .md or .yml file containing the event
- `<label>`: Existing event label (underscore_separated format)
- `--description`: Content description (MANDATORY)
- `--source`: Source specification (MANDATORY, can repeat)

### Optional Arguments (Both Modes)
- `--cause`: What caused this aspect/event
- `--impact`: Consequences of this aspect/event
- `--demo`: Analysis/demographic information

## Date Formats

```bash
# Year only
1929

# Year and month  
1929-10

# Specific date
1929-10-24

# Quarter
1929-Q4

# Date ranges
"1929 to 1933"
"1971-08-15 to 1971-12-29"
```

## Source Validation

Sources must meet specific requirements to ensure content reliability:

### Valid Source Combinations
✅ **1+ local file**: `"Name|path:~/file.txt"`  
✅ **2+ URLs**: `"Name|url:https://url1|url:https://url2"`  
✅ **2+ sources**: `--source "Name1|url:https://url1" --source "Name2|url:https://url2"`  
✅ **Mixed**: `"Name|url:https://url|path:~/file.txt"`

### Invalid Sources  
❌ **Single URL only**: `"Name|url:https://single-url"` (REJECTED)  
❌ **Empty citation**: `"|url:https://url"` (REJECTED)  
❌ **No sources**: Missing `--source` entirely (REJECTED)

## List Fields

Use the pipe separator (`|`) to create lists within any field:

```bash
--description "Item1|Item2|Item3"
--cause "Cause1|Cause2"
--impact "Impact1|Impact2|Impact3"
--demo "Analysis1|Analysis2"
```

## Label Format

Labels are automatically generated in underscore_separated format:

```bash
# Input: USA, 1929-10, "Stock Market Crash"
# Generated: usa_1929_10_stock_market_crash
```

### Valid Labels
✅ `usa_1929_10_stock_market_crash`  
✅ `gbr_1844_bank_charter_act`

### Invalid Labels  
❌ `usa-1929-10-stock-market-crash` (hyphens)  
❌ `USA_1929_Stock_Crash` (uppercase)

## Output Format

```yaml
usa_1929_10_stock_market_crash:
    date: 1929-10
    iso: USA
    title: Stock Market Crash
    content:
      - description: Black Tuesday financial crisis
        cause: Excessive speculation
        impact: 
          - Wealth destruction
          - Market confidence collapse
        source:
            - citation: Federal Reserve
              url:
                - https://fraser.stlouisfed.org
                - https://federalreservehistory.org
```

## Error Handling

The tool provides comprehensive error messages for:
- Invalid date formats
- Missing required arguments
- Insufficient source validation
- File not found errors
- Label format violations
- Non-existent labels (for add mode)

## Command Examples

```bash
# Create new event
yamlevent --new events.md 10 USA 1929 "Crisis" --description "..." --source "..."

# Add content to existing event
yamlevent --add events.md "usa_1929_crisis" --description "..." --source "..."
```

## License

AGPL-3.0

## Author

Benjamin Peeters - [benjaminpeeters.com](https://benjaminpeeters.com)
