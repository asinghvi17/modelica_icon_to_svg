#!/usr/bin/env julia

include("modelica2svg.jl")

# Configuration
msl_dir = "ModelicaStandardLibrary/Modelica"
output_base_dir = "msl_svgs_no_text"
skip_text = true  # Skip text annotations

# Statistics
mutable struct Stats
    total_files::Int
    processed::Int
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

# Process a single file
function process_file(filepath, msl_dir, output_base_dir)
    stats.processed += 1
    
    # Calculate relative path and output path
    rel_path = replace(filepath, msl_dir => "")
    rel_path = lstrip(rel_path, '/')
    
    # Create output path maintaining directory structure
    output_dir = joinpath(output_base_dir, dirname(rel_path))
    mkpath(output_dir)
    
    output_filename = replace(basename(filepath), ".mo" => ".svg")
    output_path = joinpath(output_dir, output_filename)
    
    # Progress indicator
    if stats.processed % 100 == 0
        println("Progress: $(stats.processed)/$(stats.total_files) files processed...")
    end
    
    try
        content = read(filepath, String)
        
        # Skip if no Icon annotation
        if !occursin("Icon(", content)
            stats.skipped_no_icon += 1
            return false
        end
        
        # Parse annotation
        coord_system, graphics = parse_annotation(content)
        
        if isempty(graphics)
            stats.skipped_no_graphics += 1
            return false
        end
        
        # Generate SVG (with or without text based on configuration)
        svg = to_svg(coord_system, graphics; width=200, height=200, skip_text=skip_text)
        write(output_path, svg)
        
        stats.successful += 1
        println("✓ $(rel_path) → $(output_path)")
        return true
        
    catch e
        stats.errors += 1
        println("✗ Error processing $(rel_path): $(e)")
        return false
    end
end

# Main processing
println("=== Modelica Standard Library to SVG Converter ===")
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

for file in files
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
println("  Processed:          $(stats.processed)")
println("  Successful:         $(stats.successful)")
println("  No Icon annotation: $(stats.skipped_no_icon)")
println("  No graphics:        $(stats.skipped_no_graphics)")
println("  Errors:             $(stats.errors)")
println("")
println("Time elapsed: $(elapsed) seconds")
println("Output directory: $output_base_dir")

# Success rate
if stats.processed > 0
    success_rate = round(100 * stats.successful / stats.processed, digits=1)
    println("Success rate: $(success_rate)%")
end