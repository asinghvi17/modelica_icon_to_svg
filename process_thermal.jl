#!/usr/bin/env julia

include("modelica2svg.jl")

# Directory paths - update these to match your setup
# Path to Modelica Standard Library thermal components
msl_thermal_dir = "test_msl/ModelicaStandardLibrary/Modelica/Thermal"
# Output directory for generated SVG files
output_dir = "thermal_svgs_no_text"

# Create output directory if it doesn't exist
mkpath(output_dir)

# Find all .mo files
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
function process_file(filepath, output_dir)
    println("Processing: $filepath")
    
    try
        content = read(filepath, String)
        
        # Skip if no Icon annotation
        if !occursin("Icon(", content)
            println("  No Icon annotation found, skipping")
            return false
        end
        
        # Parse annotation
        coord_system, graphics = parse_annotation(content)
        
        if isempty(graphics)
            println("  No graphics elements found, skipping")
            return false
        end
        
        # Generate output filename
        rel_path = replace(filepath, msl_thermal_dir => "")
        rel_path = replace(rel_path, "/" => "_")
        rel_path = replace(rel_path, ".mo" => ".svg")
        output_path = joinpath(output_dir, rel_path)
        
        # Generate SVG with no text
        svg = to_svg(coord_system, graphics; width=200, height=200, skip_text=true)
        write(output_path, svg)
        
        println("  Generated: $output_path")
        return true
        
    catch e
        println("  Error: $e")
        return false
    end
end

# Main processing
println("Finding Modelica files in $msl_thermal_dir...")
files = find_mo_files(msl_thermal_dir)
println("Found $(length(files)) files")

global successful = 0
for file in files
    global successful
    if process_file(file, output_dir)
        successful += 1
    end
end

println("\nProcessing complete!")
println("Successfully converted $successful out of $(length(files)) files")