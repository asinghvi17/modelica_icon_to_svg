include("modelica2svg.jl")

# Test the parser with a simple example
test_content = read("test_examples/thermal_icon.mo", String)
println("Content read:")
println(test_content)
println("\n---\n")

# Try to parse
try
    coord_system, graphics = parse_annotation(test_content)
    println("Parsed $(length(graphics)) graphics elements")
    for (i, g) in enumerate(graphics)
        println("$i: $(typeof(g))")
    end
    
    # Debug split_graphics_elements
    content_clean = replace(test_content, r"\s+" => " ")
    icon_match = match(r"Icon\s*\(\s*coordinateSystem\s*\(([^)]*)\)\s*,\s*graphics\s*=\s*\{(.*)\}\s*\)", content_clean)
    if icon_match !== nothing
        graphics_str = icon_match[2]
        println("\nGraphics string: ")
        println(graphics_str[1:min(200, length(graphics_str))])
        println("\n---\n")
        
        elements = split_graphics_elements(String(graphics_str))
        println("Split into $(length(elements)) elements")
        for (i, elem) in enumerate(elements[1:min(2, length(elements))])
            println("Element $i:")
            println(elem)
            println("---")
        end
    end
catch e
    println("Error: $e")
    println(stacktrace(catch_backtrace()))
end