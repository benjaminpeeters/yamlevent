#!/bin/bash

# yamlevent help system
# Comprehensive documentation and examples

_show_help() {
    cat << 'EOF'
yamlevent - YAML event entry management tool

DESCRIPTION:
  Create new YAML event entries or add content to existing events with
  comprehensive source validation, flexible date formats, and list support.

USAGE:
  yamlevent --new <file> <line> <iso> <date> <title> --description DESC --source SOURCE
  yamlevent --add <file> <label> --description DESC --source SOURCE
  yamlevent --help | --version

MODES:
  --new    Create new event entry with metadata and initial content
  --add    Add additional content to existing event
  --help   Show this comprehensive help
  --version Show version information

ARGUMENTS:
  REQUIRED (--new): file, line_number, iso, date, title, --description, --source  
  REQUIRED (--add): file, label, --description, --source
  OPTIONAL (both):  --cause, --impact, --demo

FORMATS:
  DATES:
    ✅ Year only:       1929
    ✅ Year-month:      1929-10
    ✅ Specific date:   1929-10-24
    ✅ Quarter:         1929-Q4, 1933-Q2
    ✅ Year period:     "1929 to 1933"
    ✅ Month period:    "1929-10 to 1930-03"
    ✅ Date period:     "1971-08-15 to 1971-12-29"
    ✅ Quarter period:  "1929-Q4 to 1933-Q1"
    ❌ Invalid:         29-10-1929, 1929/10, "1929-13"

  LABELS: (automatically generated)
    ✅ Correct format:  usa_1929_10_stock_market_crash
    ✅ Correct format:  gbr_1844_bank_charter_act
    ❌ Wrong format:    usa-1929-10-crash (hyphens not allowed)
    ❌ Wrong format:    USA_1929_Crash (uppercase not allowed)

  LISTS: (use | separator for multiple items)
    ✅ Single item:     --description "Market crash"
    ✅ Multiple items:  --description "Market crash|Economic chaos|Bank failures"
    ✅ All fields:      --cause "Cause1|Cause2" --impact "Impact1|Impact2|Impact3"

SOURCE VALIDATION:
  Sources must meet specific requirements to ensure content reliability.

  VALID SOURCE COMBINATIONS:
    ✅ 1+ local file:   --source "Name|path:~/file.txt"
    ✅ 2+ URLs in one:  --source "Name|url:https://url1|url:https://url2"
    ✅ 2+ URLs across:  --source "Name1|url:https://url1" --source "Name2|url:https://url2"
    ✅ Mixed source:    --source "Name|url:https://url|path:~/file.txt"
    ✅ Multiple mixed:  --source "Archive|path:~/file1" --source "Web|url:https://url1|url:https://url2"

  INVALID SOURCES:
    ❌ Single URL only: --source "Name|url:https://single-url" (INSUFFICIENT)
    ❌ Empty citation:  --source "|url:https://url" (MISSING CITATION)
    ❌ No sources:      (missing --source entirely) (REQUIRED)

COMMON USE CASES:

  1. CREATING A NEW EVENT:
     
     # Basic event with comprehensive fields
     yamlevent --new events.md 10 USA 1929-10 "Stock Market Crash" \
       --description "Black Tuesday triggers financial crisis|Market loses 25% in single day" \
       --cause "Excessive speculation|Margin buying overextension|Overvalued stocks" \
       --impact "Wealth destruction|Investor confidence collapses|Credit tightens" \
       --demo "Shows market psychology effects|Demonstrates leverage dangers" \
       --source "Federal Reserve|url:https://fraser.stlouisfed.org|url:https://federalreservehistory.org"

     # Event with local file source
     yamlevent --new events.md 15 GBR 1844 "Bank Charter Act" \
       --description "Establishes gold standard|Restricts private note issuance" \
       --cause "Financial instability|Need for monetary control" \
       --impact "Bank of England gains monopoly|Private banks lose privileges" \
       --demo "Centralization of monetary policy|Government control expansion" \
       --source "Parliament Archives|path:~/docs/bank_charter_1844.txt"

     # Complex date period with mixed sources
     yamlevent --new events.md 20 CHE "1971-08-15 to 1971-12-29" "Nixon Shock Response" \
       --description "Swiss franc appreciates massively|Capital flight to Switzerland" \
       --cause "Dollar devaluation|Safe haven demand|Gold backing perception" \
       --impact "Export competitiveness falls|Tourism affected|Inflation imported" \
       --demo "Small country currency challenges|Safe haven effects" \
       --source "SNB Archives|url:https://snb.ch/crisis|path:~/research/swiss_reaction.txt"

  2. ADDING CONTENT TO EXISTING EVENTS:
     
     # Add banking perspective to stock market crash
     yamlevent --add events.md "usa_1929_10_stock_market_crash" \
       --description "Banking system collapses|Bank runs spread nationwide|Rural banks fail first" \
       --cause "Overleveraged institutions|Loss of public confidence|Agricultural debt crisis" \
       --impact "9,000 banks fail by 1933|Savings accounts wiped out|Credit system breaks" \
       --demo "Shows banking interconnectedness|Reveals deposit insurance need" \
       --source "FDIC Historical Archives|path:~/research/bank_failures_1929.txt"

     # Add international perspective
     yamlevent --add events.md "usa_1929_10_stock_market_crash" \
       --description "Crisis spreads to Europe|Global trade collapses|Gold standard stress" \
       --cause "International financial integration|Cross-border lending exposure" \
       --impact "European markets crash 40-60%|International trade falls 25%|Currency crises" \
       --demo "Demonstrates financial contagion|Shows need for international cooperation" \
       --source "Bank for International Settlements|url:https://bis.org/history" \
       --source "European Archives|url:https://euro-archives.org/1929-crisis"

     # Add minimal content (description and source only)
     yamlevent --add events.md "gbr_1844_bank_charter_act" \
       --description "Implementation challenges|Regional resistance" \
       --source "Regional Records|path:~/docs/implementation_issues.txt"

  3. WORKING WITH DIFFERENT FILE TYPES:
     
     # Markdown files (.md) - content goes inside YAML blocks
     yamlevent --new events.md 5 DEU 1923-Q4 "Hyperinflation Peak" \
       --description "Currency completely collapses|Prices double daily" \
       --source "Bundesbank|url:https://bundesbank.de/history|url:https://archives.de/weimar"

     # YAML files (.yml) - content goes directly in file
     yamlevent --new events.yml 1 FRA "1933-04 to 1933-08" "Gold Reserve Act" \
       --description "Gold ownership prohibited|Federal control established" \
       --source "Treasury Archives|path:~/treasury/gold_act_records.txt"

  4. SINGLE-LINE COMMANDS (for automated tools):
     
     # When backslashes not supported, use single lines with proper quoting:
     yamlevent --new events.md 10 USA 1929-10 "Market Crash" --description "Black Tuesday crisis|Financial panic" --cause "Excessive speculation" --impact "Market collapse" --source "Fed Archives|url:https://fraser.stlouisfed.org|url:https://federalreservehistory.org"
     
     # Add content with single line:
     yamlevent --add events.md "usa_1929_10_market_crash" --description "Banking crisis spreads" --cause "Bank runs" --impact "Credit system breaks" --source "FDIC Archives|path:/absolute/path/to/file.txt"

TROUBLESHOOTING:

  ERROR: Label not found
    → Check exact label format with: grep "^[a-z0-9_]*:$" your_file.md
    → Labels are underscore_separated, lowercase only

  ERROR: Insufficient source support
    → Ensure at least: 1 path OR 2+ URLs OR 1 URL + 1 path
    → Single URLs are not accepted for reliability

  ERROR: Local file does not exist
    → Verify file path exists and is accessible
    → Use absolute paths or proper relative paths with ~

  ERROR: Invalid date format
    → Use YYYY, YYYY-MM, YYYY-MM-DD, or "YYYY to YYYY" formats
    → Quote date periods: "1929 to 1933"

WORKFLOW EXAMPLE:
  Complete 4-step workflow building a complex multi-perspective event:

  # Step 1: Create initial event with market perspective
  yamlevent --new events.md 10 USA 1929-10 "Stock Market Crash" \
    --description "Black Tuesday triggers financial crisis|Market loses 25% in single day" \
    --cause "Excessive speculation|Margin buying overextension|Overvalued stocks" \
    --impact "Wealth destruction|Investor confidence collapses|Credit tightens" \
    --demo "Shows market psychology effects|Demonstrates leverage dangers" \
    --source "Federal Reserve|url:https://fraser.stlouisfed.org|url:https://federalreservehistory.org"

  # Step 2: Add banking perspective
  yamlevent --add events.md "usa_1929_10_stock_market_crash" \
    --description "Banking system collapses|Bank runs spread nationwide|Rural banks fail first" \
    --cause "Overleveraged institutions|Loss of public confidence|Agricultural debt crisis" \
    --impact "9,000 banks fail by 1933|Savings accounts wiped out|Credit system breaks" \
    --demo "Shows banking interconnectedness|Reveals deposit insurance need" \
    --source "FDIC Historical Archives|path:~/research/bank_failures_1929.txt"

  # Step 3: Add international impact
  yamlevent --add events.md "usa_1929_10_stock_market_crash" \
    --description "Crisis spreads to Europe|Global trade collapses|Gold standard stress" \
    --cause "International financial integration|Cross-border lending exposure" \
    --impact "European markets crash 40-60%|International trade falls 25%|Currency crises" \
    --demo "Demonstrates financial contagion|Shows need for international cooperation" \
    --source "Bank for International Settlements|url:https://bis.org/history|path:~/docs/global_crisis_1929.txt"

  # Step 4: Add government response
  yamlevent --add events.md "usa_1929_10_stock_market_crash" \
    --description "Federal response evolves|Emergency measures implemented" \
    --cause "Political pressure|Economic deterioration|Banking sector lobbying" \
    --impact "New Deal programs|Banking regulations|Federal deposit insurance" \
    --demo "Government intervention expansion|Regulatory framework creation" \
    --source "National Archives|path:~/policy/new_deal_response.txt" \
    --source "Federal Reserve History|url:https://federalreservehistory.org/essays/stock-market-crash"

OUTPUT FORMAT:
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
          demo: Market psychology demonstration
          source:
              - citation: Federal Reserve
                url:
                  - https://fraser.stlouisfed.org
                  - https://federalreservehistory.org
        - description: Banking system collapse
          cause: Overleveraged institutions
          impact: Credit system breakdown
          source:
              - citation: FDIC Archives
                path:
                  - ~/research/bank_failures.txt

FIELD DESCRIPTIONS:
  description: Main event description or content summary
  cause:       What caused this event or aspect
  impact:      Consequences and effects
  demo:        Demographic/analytical information
  source:      Supporting documentation and references

IMPORTANT USAGE NOTES:

  COMMAND LINE FORMATTING:
    - Examples show "\" for readability, but in automated tools use single lines
    - Combine all arguments on one line when backslashes aren't supported
    - Always quote arguments containing spaces, pipes, or special characters

  QUOTING REQUIREMENTS:
    - ALWAYS quote: dates with "to", titles with spaces, descriptions with |
    - ALWAYS quote: source citations, paths with ~, complex arguments
    - Example: --description "Crisis spreads|Markets crash" (note the quotes)

  PATH REQUIREMENTS:
    - File paths must exist and be readable
    - Use absolute paths when possible: /full/path/to/file.txt
    - Tilde expansion works: ~/file.txt expands to /home/user/file.txt
    - Ensure file permissions allow reading

  SPECIAL CHARACTERS:
    - Pipe character | separates list items (must be quoted)
    - Quotes, backslashes, and $ symbols in text may need escaping
    - Test complex arguments in quotes: --description "Text with 'quotes'"

For bug reports and issues: https://github.com/benjaminpeeters/yamlevent/issues
EOF
}
