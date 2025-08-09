include("modelica2svg.jl")

# Test with the annotation string directly
annotation_str = """
annotation (
    Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
      Line(
        origin={-47.5,11.6667},
        points={{-2.5,-91.6667},{17.5,-71.6667},{-22.5,-51.6667},{17.5,-31.6667},{-22.5,-11.667},{17.5,8.3333},{-2.5,28.3333},{-2.5,48.3333}},
        smooth=Smooth.Bezier),
      Polygon(
        origin={-50.0,68.333},
        pattern=LinePattern.None,
        fillPattern=FillPattern.Solid,
        points={{0.0,21.667},{-10.0,-8.333},{10.0,-8.333}})}))
"""

println("Testing parse_annotation...")

# First test the regex
content_clean = replace(annotation_str, r"\s+" => " ")
println("Cleaned content (first 200 chars):")
println(content_clean[1:min(200, length(content_clean))])

icon_match = match(r"Icon\s*\(\s*coordinateSystem\s*\(([^)]*)\)\s*,\s*graphics\s*=\s*\{(.*)\}\s*\)", content_clean)
if icon_match !== nothing
    println("\nRegex matched!")
    println("Coordinate system: $(icon_match[1])")
    println("Graphics string length: $(length(icon_match[2]))")
    println("Graphics string (first 200 chars): $(icon_match[2][1:min(200, length(icon_match[2]))])")
else
    println("\nRegex did not match!")
end

# Test split_graphics_elements directly
if icon_match !== nothing
    graphics_str = icon_match[2]
    println("\nTesting split_graphics_elements...")
    elements = split_graphics_elements(String(graphics_str))
    println("Split found $(length(elements)) elements")
    for (i, elem) in enumerate(elements)
        println("\nElement $i:")
        println(elem)
        
        # Test points regex
        points_match = match(r"points\s*=\s*\{([^}]+)\}", elem)
        if points_match !== nothing
            println("Points match found: $(points_match[1])")
        else
            println("No points match")
        end
    end
end

try
    coord_system, graphics = parse_annotation(annotation_str)
    println("\nParse succeeded! Got $(length(graphics)) graphics")
    
    for (i, g) in enumerate(graphics)
        println("$i: $(typeof(g))")
        if g isa Line
            println("   Points: $(length(g.points))")
            println("   Origin: $(g.origin)")
            println("   Smooth: $(g.smooth)")
        elseif g isa Polygon
            println("   Points: $(length(g.points))")
            println("   Origin: $(g.origin)")
            println("   FillPattern: $(g.fillPattern)")
        end
    end
    
    # Generate SVG
    svg = to_svg(coord_system, graphics)
    println("\nGenerated SVG:")
    println(svg)
    
catch e
    println("Error: $e")
    for frame in stacktrace(catch_backtrace())
        println("  $frame")
    end
end