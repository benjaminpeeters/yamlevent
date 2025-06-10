#!/bin/bash

# yamlevent --new implementation
# Create new YAML event entries

_yamlevent_new() {
    # Validate minimum arguments
    if [[ $# -lt 5 ]]; then
        echo "ERROR: Missing required arguments" >&2
        echo "USAGE: yamlevent --new <file> <line> <iso> <date> <title> --description DESC --source SOURCE" >&2
        echo "       Run 'yamlevent --help' for detailed information" >&2
        return 1
    fi
    
    local file="$1"
    local line_number="$2"
    local iso="$3"
    local date="$4"
    local title="$5"
    shift 5
    
    # Validate file and line number
    if [[ ! "$line_number" =~ ^[0-9]+$ ]] || [[ "$line_number" -lt 1 ]]; then
        echo "ERROR: line_number must be a positive integer, got: '$line_number'" >&2
        return 1
    fi
    
    # Initialize variables
    local description="" cause="" impact="" demo=""
    local -a sources=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --description)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "ERROR: --description requires a value" >&2
                    return 1
                fi
                description="$2"; shift 2 ;;
            --cause)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "ERROR: --cause requires a value" >&2
                    return 1
                fi
                cause="$2"; shift 2 ;;
            --impact)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "ERROR: --impact requires a value" >&2
                    return 1
                fi
                impact="$2"; shift 2 ;;
            --demo)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "ERROR: --demo requires a value" >&2
                    return 1
                fi
                demo="$2"; shift 2 ;;
            --source)
                if [[ -z "$2" || "$2" == --* ]]; then
                    echo "ERROR: --source requires a value" >&2
                    return 1
                fi
                sources+=("$2"); shift 2 ;;
            *)
                echo "ERROR: Unknown option '$1'" >&2
                echo "       Run 'yamlevent --help' for usage information" >&2
                return 1 ;;
        esac
    done
    
    # Validate required fields
    if [[ -z "$description" ]]; then
        echo "ERROR: --description is required (provide event description)" >&2
        return 1
    fi
    
    if [[ ${#sources[@]} -eq 0 ]]; then
        echo "ERROR: At least one --source is required" >&2
        return 1
    fi
    
    # Validate date format
    if ! _validate_date_format "$date"; then
        echo "ERROR: Invalid date format '$date'" >&2
        echo "       Supported formats: YYYY, YYYY-MM, YYYY-MM-DD, YYYY-Q[1-4], 'YYYY to YYYY' periods" >&2
        echo "       Examples: 1933, 1933-04, 1933-04-05, 1933-Q2, '1929 to 1939'" >&2
        return 1
    fi
    
    # Validate ISO code (basic check)
    if [[ ! "$iso" =~ ^[A-Z]{3}$ ]]; then
        echo "ERROR: ISO code must be 3 uppercase letters, got: '$iso'" >&2
        echo "       Examples: USA, GBR, CHE, DEU, FRA" >&2
        return 1
    fi
    
    # Validate sources
    for source_spec in "${sources[@]}"; do
        if ! _validate_source_spec "$source_spec"; then
            return 1
        fi
    done
    
    # Validate overall source requirements
    if ! _validate_overall_source_requirements; then
        return 1
    fi
    
    # Generate label
    local label="$(_generate_label "$iso" "$date" "$title")"
    
    # Build YAML content - label + metadata + content array + ONE trailing blank line
    local content="${label}:
    date: ${date}
    iso: ${iso}
    title: ${title}
    content:
      - "
    
    # Add description field with list support (first field)
    _add_field_to_content_item "description" "$description" "true"
    
    # Add optional fields (not first)
    [[ -n "$cause" ]] && _add_field_to_content_item "cause" "$cause" "false"
    [[ -n "$impact" ]] && _add_field_to_content_item "impact" "$impact" "false"
    [[ -n "$demo" ]] && _add_field_to_content_item "demo" "$demo" "false"
    
    # Add sources
    _add_sources_to_content_item
    
    # ALWAYS add exactly ONE trailing blank line (label-level entry requirement)
    content+="

"
    
    # Insert into file
    local temp_file=$(/usr/bin/mktemp)
    if [[ -f "$file" ]]; then
        local file_lines=$(/usr/bin/wc -l < "$file")
        if [[ "$line_number" -gt $((file_lines + 1)) ]]; then
            echo "ERROR: line_number $line_number exceeds file length ($file_lines lines)" >&2
            /usr/bin/rm -f "$temp_file"
            return 1
        fi
        /usr/bin/head -n $((line_number - 1)) "$file" > "$temp_file"
        echo -n "$content" >> "$temp_file"
        /usr/bin/tail -n +$line_number "$file" >> "$temp_file"
    else
        echo -n "$content" > "$temp_file"
    fi
    /usr/bin/mv "$temp_file" "$file"
    
    echo "SUCCESS: Created label '$label' in $file at line $line_number"
}