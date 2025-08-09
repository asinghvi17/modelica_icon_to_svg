include("modelica2svg.jl")

# Test the parser with a simple example
# Note: Update the path below to point to your test Modelica file
# test_content = read("path/to/your/test.mo", String)

# Example annotation for testing
test_content = """
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

println("Content to test:")
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