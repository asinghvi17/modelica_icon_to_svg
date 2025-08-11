#!/usr/bin/env julia

include("modelica2svg.jl")

# Configuration
msl_dir = "ModelicaStandardLibrary/Modelica"
output_base_dir = "msl_icons_structured"
skip_text = true  # Skip text annotations

# Statistics
mutable struct Stats
    total_files::Int
    total_components::Int
    successful::Int
    skipped_no_icon::Int
    skipped_no_graphics::Int
    errors::Int
end

stats = Stats(0, 0, 0, 0, 0, 0)

# Find all .mo files recursively
function find_mo_files(dir)
    files = String[]
    for (root, dirs, filenames) in walkdir(dir)
        for file in filenames
            if endswith(file, ".mo")
                push!(files, joinpath(root, file))
            end
        end
    end
    return files
end

# Extract component name from annotation context
function extract_component_name(content, icon_start_pos)
    # Look backwards from the Icon annotation to find the component declaration
    before_icon = content[1:icon_start_pos]
    
    # Common patterns for component declarations
    patterns = [
        r"(?:model|block|connector|package|record|function|type|class)\s+(\w+)"i,
        r"partial\s+(?:model|block|connector|package|record|function|type|class)\s+(\w+)"i,
        r"replaceable\s+(?:model|block|connector|package|record|function|type|class)\s+(\w+)"i,
    ]
    
    # Search backwards for the nearest component declaration
    for pattern in patterns
        matches = collect(eachmatch(pattern, before_icon))
        if !isempty(matches)
            # Get the last match (closest to the Icon annotation)
            return String(matches[end].captures[1])
        end
    end
    
    return nothing
end

# Find all Icon annotations in content
function find_all_icons(content)
    icons = []
    
    # Find all Icon( occurrences
    icon_pattern = r"Icon\s*\("
    
    for match in eachmatch(icon_pattern, content)
        icon_start = match.offset
        
        # Extract component name
        component_name = extract_component_name(content, icon_start)
        if component_name === nothing
            continue
        end
        
        # Find the matching closing parenthesis for this Icon annotation
        # This is a simplified approach - may need refinement for complex cases
        paren_count = 1
        pos = icon_start + length(match.match)
        icon_end = pos
        
        while pos <= length(content) && paren_count > 0
            if content[pos] == '('
                paren_count += 1
            elseif content[pos] == ')'
                paren_count -= 1
            end
            if paren_count == 0
                icon_end = pos
            end
            pos += 1
        end
        
        # Extract the full Icon annotation
        icon_annotation = content[icon_start:icon_end]
        
        push!(icons, (name=component_name, annotation=icon_annotation))
    end
    
    return icons
end

# Process a single file with multiple components
function process_file(filepath, msl_dir, output_base_dir)
    # Calculate relative path
    rel_path = replace(filepath, msl_dir => "")
    rel_path = lstrip(rel_path, '/')
    
    # Base filename without extension
    base_name = replace(basename(filepath), ".mo" => "")
    
    # Create a folder for this .mo file within the directory structure
    output_dir = joinpath(output_base_dir, dirname(rel_path), base_name)
    mkpath(output_dir)
    
    components_found = 0
    components_processed = 0
    
    try
        content = read(filepath, String)
        
        # Find all Icon annotations in the file
        icons = find_all_icons(content)
        
        if isempty(icons)
            stats.skipped_no_icon += 1
            return 0
        end
        
        components_found = length(icons)
        stats.total_components += components_found
        
        for (idx, icon_data) in enumerate(icons)
            try
                # Create annotation string that parse_annotation expects
                annotation_str = "annotation(" * icon_data.annotation * ")"
                
                # Parse annotation
                coord_system, graphics = parse_annotation(annotation_str)
                
                if isempty(graphics)
                    stats.skipped_no_graphics += 1
                    continue
                end
                
                # Generate output filename - just use component name since we're in a folder
                output_filename = icon_data.name * ".svg"
                output_path = joinpath(output_dir, output_filename)
                
                # Generate SVG
                svg = to_svg(coord_system, graphics; width=200, height=200, skip_text=skip_text)
                write(output_path, svg)
                
                stats.successful += 1
                components_processed += 1
                println("  ✓ $(icon_data.name) → $(output_path)")
                
            catch e
                stats.errors += 1
                println("  ✗ Error processing $(icon_data.name): $(e)")
            end
        end
        
        if components_processed > 0
            println("✓ $(rel_path): $(components_processed)/$(components_found) components")
        end
        
        return components_processed
        
    catch e
        stats.errors += 1
        println("✗ Error reading $(rel_path): $(e)")
        return 0
    end
end

# Main processing
println("=== Modelica Standard Library to SVG Converter ===")
println("=== Extracting ALL Components ===")
println("Source: $msl_dir")
println("Output: $output_base_dir")
println("")

# Check if MSL directory exists
if !isdir(msl_dir)
    println("Error: MSL directory not found at $msl_dir")
    println("Please ensure the Modelica Standard Library is cloned.")
    exit(1)
end

# Create output directory
mkpath(output_base_dir)

# Find all Modelica files
println("Scanning for Modelica files...")
files = find_mo_files(msl_dir)
stats.total_files = length(files)
println("Found $(stats.total_files) .mo files")
println("")

# Process each file
println("Starting conversion...")
println("=" ^ 50)

start_time = time()

for (idx, file) in enumerate(files)
    if idx % 100 == 0
        println("\nProgress: $(idx)/$(stats.total_files) files...")
    end
    process_file(file, msl_dir, output_base_dir)
end

end_time = time()
elapsed = round(end_time - start_time, digits=2)

# Print summary
println("")
println("=" ^ 50)
println("=== Conversion Complete ===")
println("")
println("Statistics:")
println("  Total files:        $(stats.total_files)")
println("  Total components:   $(stats.total_components)")
println("  Successful SVGs:    $(stats.successful)")
println("  No Icon annotation: $(stats.skipped_no_icon)")
println("  No graphics:        $(stats.skipped_no_graphics)")
println("  Errors:             $(stats.errors)")
println("")
println("Time elapsed: $(elapsed) seconds")
println("Output directory: $output_base_dir")

# Success rate
if stats.total_components > 0
    success_rate = round(100 * stats.successful / stats.total_components, digits=1)
    println("Success rate: $(success_rate)%")
end