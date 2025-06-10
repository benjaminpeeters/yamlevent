#!/bin/bash

# yamlevent --add implementation  
# Add content to existing YAML event entries

_yamlevent_add() {
    # Validate minimum arguments
    if [[ $# -lt 2 ]]; then
        echo "ERROR: Missing required arguments" >&2
        echo "USAGE: yamlevent --add <file> <label> --description DESC --source SOURCE" >&2
        echo "       Run 'yamlevent --help' for detailed information" >&2
        return 1
    fi
    
    local file="$1" label="$2"
    shift 2
    
    # Validate file exists
    if [[ ! -f "$file" ]]; then
        echo "ERROR: File does not exist: '$file'" >&2
        return 1
    fi
    
    # Validate label format (basic check)
    if [[ ! "$label" =~ ^[a-z0-9_]+$ ]]; then
        echo "ERROR: Label must be underscore-separated (lowercase, numbers, underscores only), got: '$label'" >&2
        echo "       Expected format: 'iso_date_title' (e.g., 'usa_1933_04_05_gold_reserve_act')" >&2
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
        echo "ERROR: --description is required (provide content description)" >&2
        return 1
    fi
    
    if [[ ${#sources[@]} -eq 0 ]]; then
        echo "ERROR: At least one --source is required" >&2
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
    
    # Find label line (reliable anchor point)
    local label_line=$(/usr/bin/grep -n "^${label}:" "$file" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
    if [[ -z "$label_line" ]]; then
        echo "ERROR: Label '$label' not found in $file" >&2
        echo "       Available labels:" >&2
        /usr/bin/grep "^[a-z0-9_]*:$" "$file" | /usr/bin/head -5 | /usr/bin/sed 's/^/         /'
        local label_count=$(/usr/bin/grep -c "^[a-z0-9_]*:$" "$file")
        if [[ $label_count -gt 5 ]]; then
            echo "         ... and $((label_count - 5)) more"
        fi
        return 1
    fi
    
    # FIXED BOUNDARY DETECTION: Find end boundary of this specific label
    local boundary_line
    if [[ "$file" == *.md ]]; then
        # For .md files: Find the next label OR the closing ``` (whichever comes first)
        local next_label_line=$(/usr/bin/tail -n +$((label_line + 1)) "$file" | /usr/bin/grep -n "^[a-z0-9_]*:$" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
        local yaml_end_line=$(/usr/bin/tail -n +$((label_line + 1)) "$file" | /usr/bin/grep -n '^```$' | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
        
        # Choose the earlier boundary (next label or YAML end)
        if [[ -n "$next_label_line" && -n "$yaml_end_line" ]]; then
            if [[ $next_label_line -lt $yaml_end_line ]]; then
                boundary_line=$((label_line + next_label_line))
            else
                boundary_line=$((label_line + yaml_end_line))
            fi
        elif [[ -n "$next_label_line" ]]; then
            boundary_line=$((label_line + next_label_line))
        elif [[ -n "$yaml_end_line" ]]; then
            boundary_line=$((label_line + yaml_end_line))
        else
            echo "ERROR: Could not find boundary after label '$label' in markdown file" >&2
            return 1
        fi
    else
        # For .yml files: find next label or EOF
        local next_label=$(/usr/bin/tail -n +$((label_line + 1)) "$file" | /usr/bin/grep -n "^[a-z0-9_]*:$" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)
        if [[ -n "$next_label" ]]; then
            boundary_line=$((label_line + next_label))
        else
            boundary_line=$(($(/usr/bin/wc -l < "$file") + 1))
        fi
    fi
    
    # Check if content array exists within this label's boundary
    local content_array_line=$(/usr/bin/sed -n "${label_line},$((boundary_line - 1))p" "$file" | /usr/bin/grep -n "^    content:$" | /usr/bin/cut -d: -f1)
    if [[ -z "$content_array_line" ]]; then
        echo "ERROR: Label '$label' found but contains no 'content:' array" >&2
        echo "       This label may have been created incorrectly or corrupted" >&2
        echo "       Expected 'content:' array created by yamlevent --new" >&2
        return 1
    fi
    
    # Build new content array item
    local new_content="      - "
    
    # Add description field with list support (first field)
    _add_field_to_new_content_item "description" "$description" "true"
    
    # Add optional fields (not first)
    [[ -n "$cause" ]] && _add_field_to_new_content_item "cause" "$cause" "false"
    [[ -n "$impact" ]] && _add_field_to_new_content_item "impact" "$impact" "false"
    [[ -n "$demo" ]] && _add_field_to_new_content_item "demo" "$demo" "false"
    
    # Add sources
    _add_sources_to_new_content_item
    
    # IMPROVED INSERTION: Find the correct insertion point within this label's boundary
    local temp_file=$(/usr/bin/mktemp)
    
    # Find the last content item in this label to insert after it
    local last_content_line
    for ((i = boundary_line - 1; i >= label_line; i--)); do
        local line_content=$(/usr/bin/sed -n "${i}p" "$file")
        # Look for source array end, path array end, or URL array end (deepest nesting)
        if [[ "$line_content" =~ ^[[:space:]]*-[[:space:]]+(https://|/) ]] || \
           [[ "$line_content" =~ ^[[:space:]]*demo:[[:space:]] ]] || \
           [[ "$line_content" =~ ^[[:space:]]*impact:[[:space:]] ]] || \
           [[ "$line_content" =~ ^[[:space:]]*cause:[[:space:]] ]] || \
           [[ "$line_content" =~ ^[[:space:]]*description:[[:space:]] ]]; then
            last_content_line=$i
            break
        fi
    done
    
    # If we can't find a good insertion point, fall back to before the blank line
    if [[ -z "$last_content_line" ]]; then
        # Find the blank line before the boundary
        for ((i = boundary_line - 1; i >= label_line; i--)); do
            local line_content=$(/usr/bin/sed -n "${i}p" "$file")
            if [[ -z "$line_content" ]]; then
                last_content_line=$((i - 1))
                break
            fi
        done
    fi
    
    # Insert new content after the last content line
    local insertion_point=$((last_content_line + 1))
    
    # Build the file with new content inserted
    if ! /usr/bin/head -n $last_content_line "$file" > "$temp_file"; then
        echo "ERROR: Failed to read file content before insertion point" >&2
        /usr/bin/rm -f "$temp_file"
        return 1
    fi
    
    echo "$new_content" >> "$temp_file"
    
    if ! /usr/bin/tail -n +$insertion_point "$file" >> "$temp_file"; then
        echo "ERROR: Failed to read file content after insertion point" >&2
        /usr/bin/rm -f "$temp_file"
        return 1
    fi
    
    if ! /usr/bin/mv "$temp_file" "$file"; then
        echo "ERROR: Failed to update file '$file'" >&2
        return 1
    fi
    
    echo "SUCCESS: Added content item to label '$label' in $file"
}