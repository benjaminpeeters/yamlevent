#!/bin/bash

# yamlevent utility functions
# Shared helper functions for validation and content generation

# Validate a single source specification
_validate_source_spec() {
    local spec="$1"
    
    # Extract citation (everything before first |)
    local citation="${spec%%|*}"
    if [[ -z "$citation" ]]; then
        echo "ERROR: Source citation cannot be empty in '$spec'" >&2
        echo "       Expected format: 'Citation|url:URL|path:PATH'" >&2
        return 1
    fi
    
    # Get the rest after citation
    local rest="${spec#*|}"
    if [[ "$rest" == "$spec" ]]; then
        echo "ERROR: Source must have at least one url: or path: component in '$spec'" >&2
        echo "       Expected format: 'Citation|url:URL|path:PATH'" >&2
        return 1
    fi
    
    # Split by | and validate each component
    local has_url=false has_path=false
    local component
    
    # Process each component after the citation
    while [[ -n "$rest" ]]; do
        if [[ "$rest" == *"|"* ]]; then
            component="${rest%%|*}"
            rest="${rest#*|}"
        else
            component="$rest"
            rest=""
        fi
        
        if [[ "$component" == url:* ]]; then
            has_url=true
            local url="${component#url:}"
            if [[ -z "$url" ]]; then
                echo "ERROR: Empty URL in source '$spec'" >&2
                return 1
            fi
            if ! [[ "$url" =~ ^https:// ]]; then
                echo "ERROR: URL must start with 'https://', got '$url' in source '$spec'" >&2
                return 1
            fi
        elif [[ "$component" == path:* ]]; then
            has_path=true
            local path="${component#path:}"
            if [[ -z "$path" ]]; then
                echo "ERROR: Empty path in source '$spec'" >&2
                return 1
            fi
            local expanded_path="${path/#\~/$HOME}"
            if [[ ! -f "$expanded_path" ]]; then
                echo "ERROR: Local file does not exist: '$path'" >&2
                echo "       Expanded path: '$expanded_path'" >&2
                return 1
            fi
        else
            echo "ERROR: Invalid source component '$component' in '$spec'" >&2
            echo "       Expected format: 'Citation|url:URL|path:PATH'" >&2
            return 1
        fi
    done
    
    if [[ "$has_url" == false && "$has_path" == false ]]; then
        echo "ERROR: Source must have at least one url: or path: component in '$spec'" >&2
        return 1
    fi
    
    return 0
}

# Validate overall source requirements across all sources
_validate_overall_source_requirements() {
    local url_count=0 path_count=0
    
    # Count total URLs and paths across all sources
    for spec in "${sources[@]}"; do
        local rest="${spec#*|}"
        
        # Count url: and path: components
        local temp_rest="$rest"
        while [[ -n "$temp_rest" ]]; do
            local component
            if [[ "$temp_rest" == *"|"* ]]; then
                component="${temp_rest%%|*}"
                temp_rest="${temp_rest#*|}"
            else
                component="$temp_rest"
                temp_rest=""
            fi
            
            if [[ "$component" == url:* ]]; then
                ((url_count++))
            elif [[ "$component" == path:* ]]; then
                ((path_count++))
            fi
        done
    done
    
    # Check requirements: 
    # - At least 1 path (sufficient on its own), OR
    # - At least 2 URLs, OR  
    # - At least 1 URL + 1 path
    if [[ $path_count -gt 0 ]]; then
        # At least one path - this is always sufficient
        return 0
    elif [[ $url_count -ge 2 ]]; then
        # At least 2 URLs - this is sufficient
        return 0
    else
        # Not enough sources
        echo "ERROR: Insufficient source support. Content must have:" >&2
        echo "       - At least 1 path (local file), OR" >&2
        echo "       - At least 2 URLs, OR" >&2  
        echo "       - At least 1 URL + 1 path" >&2
        echo "       Current: $url_count URLs, $path_count paths" >&2
        return 1
    fi
}

# Helper function to add field with list support to content item
_add_field_to_content_item() {
    local field_name="$1"
    local field_value="$2"
    local is_first_field="$3"  # whether this is the first field (goes on same line as -)
    
    if [[ "$field_value" == *"|"* ]]; then
        if [[ "$is_first_field" == "true" ]]; then
            content+="$field_name:"
        else
            content+="
        $field_name:"
        fi
        local value_copy="$field_value"
        while [[ "$value_copy" == *"|"* ]]; do
            local item="${value_copy%%|*}"
            [[ -n "$item" ]] && content+="
          - ${item}"
            value_copy="${value_copy#*|}"
        done
        # Add the last item
        [[ -n "$value_copy" ]] && content+="
          - ${value_copy}"
    else
        if [[ "$is_first_field" == "true" ]]; then
            content+="$field_name: ${field_value}"
        else
            content+="
        $field_name: ${field_value}"
        fi
    fi
}

# Helper function to add sources to content item
_add_sources_to_content_item() {
    # Always use sources array format
    content+="
        source:"
    
    for spec in "${sources[@]}"; do
        local citation="${spec%%|*}"
        local rest="${spec#*|}"
        
        content+="
            - citation: ${citation}"
        
        # Process URLs and paths for this source
        local -a urls=()
        local -a paths=()
        
        while [[ -n "$rest" ]]; do
            local component
            if [[ "$rest" == *"|"* ]]; then
                component="${rest%%|*}"
                rest="${rest#*|}"
            else
                component="$rest"
                rest=""
            fi
            
            if [[ "$component" == url:* ]]; then
                urls+=("${component#url:}")
            elif [[ "$component" == path:* ]]; then
                paths+=("${component#path:}")
            fi
        done
        
        # Add URLs array (only if URLs exist)
        if [[ ${#urls[@]} -gt 0 ]]; then
            content+="
              url:"
            for url in "${urls[@]}"; do
                content+="
                - ${url}"
            done
        fi
        
        # Add paths array (only if paths exist)
        if [[ ${#paths[@]} -gt 0 ]]; then
            content+="
              path:"
            for path in "${paths[@]}"; do
                content+="
                - ${path}"
            done
        fi
    done
}

# Helper function to add field with list support to new content item
_add_field_to_new_content_item() {
    local field_name="$1"
    local field_value="$2"
    local is_first_field="$3"  # whether this is the first field (goes on same line as -)
    
    if [[ "$field_value" == *"|"* ]]; then
        if [[ "$is_first_field" == "true" ]]; then
            new_content+="$field_name:"
        else
            new_content+="
        $field_name:"
        fi
        local value_copy="$field_value"
        while [[ "$value_copy" == *"|"* ]]; do
            local item="${value_copy%%|*}"
            [[ -n "$item" ]] && new_content+="
          - ${item}"
            value_copy="${value_copy#*|}"
        done
        # Add the last item
        [[ -n "$value_copy" ]] && new_content+="
          - ${value_copy}"
    else
        if [[ "$is_first_field" == "true" ]]; then
            new_content+="$field_name: ${field_value}"
        else
            new_content+="
        $field_name: ${field_value}"
        fi
    fi
}

# Helper function to add sources to new content item
_add_sources_to_new_content_item() {
    # Always use sources array format
    new_content+="
        source:"
    
    for spec in "${sources[@]}"; do
        local citation="${spec%%|*}"
        local rest="${spec#*|}"
        
        new_content+="
            - citation: ${citation}"
        
        # Process URLs and paths for this source
        local -a urls=()
        local -a paths=()
        
        while [[ -n "$rest" ]]; do
            local component
            if [[ "$rest" == *"|"* ]]; then
                component="${rest%%|*}"
                rest="${rest#*|}"
            else
                component="$rest"
                rest=""
            fi
            
            if [[ "$component" == url:* ]]; then
                urls+=("${component#url:}")
            elif [[ "$component" == path:* ]]; then
                paths+=("${component#path:}")
            fi
        done
        
        # Add URLs array (only if URLs exist)
        if [[ ${#urls[@]} -gt 0 ]]; then
            new_content+="
              url:"
            for url in "${urls[@]}"; do
                new_content+="
                - ${url}"
            done
        fi
        
        # Add paths array (only if paths exist)
        if [[ ${#paths[@]} -gt 0 ]]; then
            new_content+="
              path:"
            for path in "${paths[@]}"; do
                new_content+="
                - ${path}"
            done
        fi
    done
}

# Generate underscore-separated label from ISO, date, and title
_generate_label() {
    local iso="$1" date="$2" title="$3"
    local clean_iso=$(echo "$iso" | /usr/bin/tr '[:upper:]' '[:lower:]')
    local clean_date=$(echo "$date" | /usr/bin/tr '[:upper:]' '[:lower:]' | /usr/bin/sed 's/[^a-z0-9]/_/g; s/__*/_/g; s/^_\|_$//g')
    local clean_title=$(echo "$title" | /usr/bin/tr '[:upper:]' '[:lower:]' | /usr/bin/sed 's/[^a-z0-9]/_/g; s/__*/_/g; s/^_\|_$//g')
    echo "${clean_iso}_${clean_date}_${clean_title}"
}

# Validate date format
_validate_date_format() {
    local date="$1"
    
    # Single dates: YYYY, YYYY-MM, YYYY-MM-DD, YYYY-Q#
    if [[ "$date" =~ ^[0-9]{4}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-[0-9]{2}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-Q[1-4]$ ]]; then
        return 0
    fi
    
    # Periods: "YYYY to YYYY" format variations
    if [[ "$date" =~ ^[0-9]{4}[[:space:]]to[[:space:]][0-9]{4}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-[0-9]{2}[[:space:]]to[[:space:]][0-9]{4}-[0-9]{2}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]to[[:space:]][0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || \
       [[ "$date" =~ ^[0-9]{4}-Q[1-4][[:space:]]to[[:space:]][0-9]{4}-Q[1-4]$ ]]; then
        return 0
    fi
    
    return 1
}