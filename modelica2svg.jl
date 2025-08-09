#!/usr/bin/env julia

using ArgParse

# Data structures for graphical elements
abstract type GraphicItem end

struct CoordinateSystem
    extent::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}}
    preserveAspectRatio::Bool
    
    CoordinateSystem(; extent=((-100.0,-100.0),(100.0,100.0)), preserveAspectRatio=true) = 
        new(extent, preserveAspectRatio)
end

struct Line <: GraphicItem
    points::Vector{Tuple{Float64,Float64}}
    origin::Tuple{Float64,Float64}
    color::Tuple{Int,Int,Int}
    pattern::Symbol
    thickness::Float64
    smooth::Symbol
    visible::Bool
    rotation::Float64
    
    Line(; points=[], origin=(0.0,0.0), color=(0,0,0), pattern=:Solid, 
         thickness=0.25, smooth=:None, visible=true, rotation=0.0) = 
        new(points, origin, color, pattern, thickness, smooth, visible, rotation)
end

struct Rectangle <: GraphicItem
    extent::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}}
    origin::Tuple{Float64,Float64}
    lineColor::Tuple{Int,Int,Int}
    fillColor::Tuple{Int,Int,Int}
    pattern::Symbol
    fillPattern::Symbol
    lineThickness::Float64
    borderPattern::Symbol
    radius::Float64
    visible::Bool
    rotation::Float64
    
    Rectangle(; extent=((-50.0,-50.0),(50.0,50.0)), origin=(0.0,0.0), 
             lineColor=(0,0,0), fillColor=(255,255,255), pattern=:Solid,
             fillPattern=:None, lineThickness=0.25, borderPattern=:None,
             radius=0.0, visible=true, rotation=0.0) = 
        new(extent, origin, lineColor, fillColor, pattern, fillPattern, 
            lineThickness, borderPattern, radius, visible, rotation)
end

struct Ellipse <: GraphicItem
    extent::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}}
    origin::Tuple{Float64,Float64}
    lineColor::Tuple{Int,Int,Int}
    fillColor::Tuple{Int,Int,Int}
    pattern::Symbol
    fillPattern::Symbol
    lineThickness::Float64
    startAngle::Float64
    endAngle::Float64
    closure::Symbol
    visible::Bool
    rotation::Float64
    
    Ellipse(; extent=((-50.0,-50.0),(50.0,50.0)), origin=(0.0,0.0),
           lineColor=(0,0,0), fillColor=(255,255,255), pattern=:Solid,
           fillPattern=:None, lineThickness=0.25, startAngle=0.0, 
           endAngle=360.0, closure=:Chord, visible=true, rotation=0.0) = 
        new(extent, origin, lineColor, fillColor, pattern, fillPattern,
            lineThickness, startAngle, endAngle, closure, visible, rotation)
end

struct Polygon <: GraphicItem
    points::Vector{Tuple{Float64,Float64}}
    origin::Tuple{Float64,Float64}
    lineColor::Tuple{Int,Int,Int}
    fillColor::Tuple{Int,Int,Int}
    pattern::Symbol
    fillPattern::Symbol
    lineThickness::Float64
    smooth::Symbol
    visible::Bool
    rotation::Float64
    
    Polygon(; points=[], origin=(0.0,0.0), lineColor=(0,0,0), 
           fillColor=(0,0,0), pattern=:Solid, fillPattern=:Solid,
           lineThickness=0.25, smooth=:None, visible=true, rotation=0.0) = 
        new(points, origin, lineColor, fillColor, pattern, fillPattern,
            lineThickness, smooth, visible, rotation)
end

struct Text <: GraphicItem
    extent::Tuple{Tuple{Float64,Float64},Tuple{Float64,Float64}}
    textString::String
    origin::Tuple{Float64,Float64}
    fontSize::Float64
    fontName::String
    textColor::Tuple{Int,Int,Int}
    horizontalAlign::Symbol
    visible::Bool
    rotation::Float64
    
    Text(; extent=((-50.0,-50.0),(50.0,50.0)), textString="", 
         origin=(0.0,0.0), fontSize=0.0, fontName="Arial",
         textColor=(0,0,0), horizontalAlign=:Center, 
         visible=true, rotation=0.0) = 
        new(extent, textString, origin, fontSize, fontName, textColor,
            horizontalAlign, visible, rotation)
end

# Parser functions
function parse_annotation(content::String)
    # Extract Icon annotation - handle multiline
    content_clean = replace(content, r"\s+" => " ")
    
    # Look for Icon annotation with coordinateSystem
    icon_match = match(r"Icon\s*\(\s*coordinateSystem\s*\(([^)]*)\)\s*,\s*graphics\s*=\s*\{(.*)\}\s*\)", content_clean)
    
    if icon_match === nothing
        # Try without coordinateSystem
        icon_match = match(r"Icon\s*\(\s*graphics\s*=\s*\{(.*)\}\s*\)", content_clean)
        if icon_match === nothing
            error("No Icon annotation found")
        end
        coord_system = CoordinateSystem()
        graphics_str = icon_match[1]
    else
        coord_system = parse_coordinate_system(icon_match[1])
        graphics_str = icon_match[2]
    end
    
    graphics = parse_graphics(graphics_str)
    
    return coord_system, graphics
end

function parse_coordinate_system(coord_str::AbstractString)
    # Default values
    extent = ((-100.0,-100.0),(100.0,100.0))
    
    # Extract extent
    extent_match = match(r"extent\s*=\s*\{\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*,\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*\}", coord_str)
    if extent_match !== nothing
        x1, y1, x2, y2 = parse.(Float64, extent_match.captures)
        extent = ((x1, y1), (x2, y2))
    end
    
    return CoordinateSystem(extent=extent)
end

function parse_graphics(graphics_str::AbstractString)
    graphics = GraphicItem[]
    
    # Split by top-level elements
    elements = split_graphics_elements(String(graphics_str))
    
    for element in elements
        element = strip(element)
        if startswith(element, "Line")
            push!(graphics, parse_line(element))
        elseif startswith(element, "Rectangle")
            push!(graphics, parse_rectangle(element))
        elseif startswith(element, "Ellipse")
            push!(graphics, parse_ellipse(element))
        elseif startswith(element, "Polygon")
            push!(graphics, parse_polygon(element))
        elseif startswith(element, "Text")
            push!(graphics, parse_text(element))
        end
    end
    
    return graphics
end

function split_graphics_elements(graphics_str::String)
    elements = String[]
    i = 1
    
    while i <= length(graphics_str)
        # Skip whitespace and commas
        while i <= length(graphics_str) && (isspace(graphics_str[i]) || graphics_str[i] == ',')
            i += 1
        end
        
        if i > length(graphics_str)
            break
        end
        
        # Find the element type
        start = i
        while i <= length(graphics_str) && graphics_str[i] != '('
            i += 1
        end
        
        if i > length(graphics_str)
            break
        end
        
        # Now find the matching closing parenthesis
        depth = 0
        element_start = start
        
        while i <= length(graphics_str)
            if graphics_str[i] == '('
                depth += 1
            elseif graphics_str[i] == ')'
                depth -= 1
                if depth == 0
                    push!(elements, strip(graphics_str[element_start:i]))
                    i += 1
                    break
                end
            end
            i += 1
        end
    end
    
    return elements
end

function parse_line(line_str::AbstractString)
    # Extract parameters
    params = Dict{Symbol,Any}()
    
    # Parse origin
    origin_match = match(r"origin\s*=\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}", line_str)
    if origin_match !== nothing
        params[:origin] = (parse(Float64, origin_match[1]), parse(Float64, origin_match[2]))
    end
    
    # Parse points - handle nested braces
    points_idx = findfirst("points", line_str)
    if points_idx !== nothing
        start_idx = findnext('{', line_str, points_idx.stop)
        if start_idx !== nothing
            # Find matching closing brace
            depth = 1
            end_idx = start_idx
            for i in (start_idx+1):length(line_str)
                if line_str[i] == '{'
                    depth += 1
                elseif line_str[i] == '}'
                    depth -= 1
                    if depth == 0
                        end_idx = i
                        break
                    end
                end
            end
            
            points_str = line_str[start_idx+1:end_idx-1]
            points = Tuple{Float64,Float64}[]
            for point_match in eachmatch(r"\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}", points_str)
                push!(points, (parse(Float64, point_match[1]), parse(Float64, point_match[2])))
            end
            params[:points] = points
        end
    end
    
    # Parse smooth
    smooth_match = match(r"smooth\s*=\s*Smooth\.(\w+)", line_str)
    if smooth_match !== nothing
        params[:smooth] = Symbol(smooth_match[1])
    end
    
    # Parse color
    color_match = match(r"color\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", line_str)
    if color_match !== nothing
        params[:color] = (parse(Int, color_match[1]), parse(Int, color_match[2]), parse(Int, color_match[3]))
    end
    
    # Parse thickness
    thickness_match = match(r"thickness\s*=\s*(\d+(?:\.\d+)?)", line_str)
    if thickness_match !== nothing
        params[:thickness] = parse(Float64, thickness_match[1])
    end
    
    return Line(; params...)
end

function parse_polygon(polygon_str::AbstractString)
    params = Dict{Symbol,Any}()
    
    # Parse origin
    origin_match = match(r"origin\s*=\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}", polygon_str)
    if origin_match !== nothing
        params[:origin] = (parse(Float64, origin_match[1]), parse(Float64, origin_match[2]))
    end
    
    # Parse points - handle nested braces
    points_idx = findfirst("points", polygon_str)
    if points_idx !== nothing
        start_idx = findnext('{', polygon_str, points_idx.stop)
        if start_idx !== nothing
            # Find matching closing brace
            depth = 1
            end_idx = start_idx
            for i in (start_idx+1):length(polygon_str)
                if polygon_str[i] == '{'
                    depth += 1
                elseif polygon_str[i] == '}'
                    depth -= 1
                    if depth == 0
                        end_idx = i
                        break
                    end
                end
            end
            
            points_str = polygon_str[start_idx+1:end_idx-1]
            points = Tuple{Float64,Float64}[]
            for point_match in eachmatch(r"\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}", points_str)
                push!(points, (parse(Float64, point_match[1]), parse(Float64, point_match[2])))
            end
            params[:points] = points
        end
    end
    
    # Parse pattern
    pattern_match = match(r"pattern\s*=\s*LinePattern\.(\w+)", polygon_str)
    if pattern_match !== nothing
        params[:pattern] = Symbol(pattern_match[1])
    end
    
    # Parse fillPattern
    fill_match = match(r"fillPattern\s*=\s*FillPattern\.(\w+)", polygon_str)
    if fill_match !== nothing
        params[:fillPattern] = Symbol(fill_match[1])
    end
    
    # Parse fillColor
    fill_color_match = match(r"fillColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", polygon_str)
    if fill_color_match !== nothing
        params[:fillColor] = (parse(Int, fill_color_match[1]), parse(Int, fill_color_match[2]), parse(Int, fill_color_match[3]))
    end
    
    return Polygon(; params...)
end

function parse_rectangle(rect_str::AbstractString)
    params = Dict{Symbol,Any}()
    
    # Parse extent
    extent_match = match(r"extent\s*=\s*\{\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*,\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*\}", rect_str)
    if extent_match !== nothing
        x1, y1, x2, y2 = parse.(Float64, extent_match.captures)
        params[:extent] = ((x1, y1), (x2, y2))
    end
    
    # Parse lineColor
    line_color_match = match(r"lineColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", rect_str)
    if line_color_match !== nothing
        params[:lineColor] = (parse(Int, line_color_match[1]), parse(Int, line_color_match[2]), parse(Int, line_color_match[3]))
    end
    
    # Parse fillColor
    fill_color_match = match(r"fillColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", rect_str)
    if fill_color_match !== nothing
        params[:fillColor] = (parse(Int, fill_color_match[1]), parse(Int, fill_color_match[2]), parse(Int, fill_color_match[3]))
    end
    
    # Parse fillPattern
    fill_match = match(r"fillPattern\s*=\s*FillPattern\.(\w+)", rect_str)
    if fill_match !== nothing
        params[:fillPattern] = Symbol(fill_match[1])
    end
    
    return Rectangle(; params...)
end

function parse_ellipse(ellipse_str::AbstractString)
    params = Dict{Symbol,Any}()
    
    # Parse extent
    extent_match = match(r"extent\s*=\s*\{\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*,\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*\}", ellipse_str)
    if extent_match !== nothing
        x1, y1, x2, y2 = parse.(Float64, extent_match.captures)
        params[:extent] = ((x1, y1), (x2, y2))
    end
    
    # Parse lineColor
    line_color_match = match(r"lineColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", ellipse_str)
    if line_color_match !== nothing
        params[:lineColor] = (parse(Int, line_color_match[1]), parse(Int, line_color_match[2]), parse(Int, line_color_match[3]))
    end
    
    # Parse fillColor
    fill_color_match = match(r"fillColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", ellipse_str)
    if fill_color_match !== nothing
        params[:fillColor] = (parse(Int, fill_color_match[1]), parse(Int, fill_color_match[2]), parse(Int, fill_color_match[3]))
    end
    
    # Parse fillPattern
    fill_match = match(r"fillPattern\s*=\s*FillPattern\.(\w+)", ellipse_str)
    if fill_match !== nothing
        params[:fillPattern] = Symbol(fill_match[1])
    end
    
    return Ellipse(; params...)
end

function parse_text(text_str::AbstractString)
    params = Dict{Symbol,Any}()
    
    # Parse extent
    extent_match = match(r"extent\s*=\s*\{\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*,\s*\{\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\}\s*\}", text_str)
    if extent_match !== nothing
        x1, y1, x2, y2 = parse.(Float64, extent_match.captures)
        params[:extent] = ((x1, y1), (x2, y2))
    end
    
    # Parse textString
    text_match = match(r"textString\s*=\s*\"([^\"]*)\"|textString\s*=\s*(\w+)", text_str)
    if text_match !== nothing
        params[:textString] = text_match[1] !== nothing ? text_match[1] : text_match[2]
    end
    
    # Parse textColor
    text_color_match = match(r"textColor\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", text_str)
    if text_color_match !== nothing
        params[:textColor] = (parse(Int, text_color_match[1]), parse(Int, text_color_match[2]), parse(Int, text_color_match[3]))
    end
    
    return Text(; params...)
end

# SVG generation functions
function to_svg(coord_system::CoordinateSystem, graphics::Vector{<:GraphicItem}; 
               width=200, height=200, skip_text=false, skip_parametric_text=false)
    # Calculate SVG viewBox from coordinate system
    ((x1, y1), (x2, y2)) = coord_system.extent
    view_width = x2 - x1
    view_height = y2 - y1
    
    svg = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="$x1 $y1 $view_width $view_height">
<g transform="scale(1,-1) translate(0,-$(y1+y2))">
"""
    
    for item in graphics
        # Skip text if requested
        if item isa Text
            if skip_text
                continue
            elseif skip_parametric_text && occursin("%", item.textString)
                continue
            end
        end
        svg *= to_svg_element(item)
    end
    
    svg *= "</g>\n</svg>"
    
    return svg
end

function to_svg_element(line::Line)
    if !line.visible
        return ""
    end
    
    # Apply origin transformation
    points_str = join(["$(p[1]+line.origin[1]),$(p[2]+line.origin[2])" for p in line.points], " ")
    
    # Convert color
    color = "rgb($(line.color[1]),$(line.color[2]),$(line.color[3]))"
    
    # Handle smooth curves
    if line.smooth == :Bezier && length(line.points) > 2
        path = bezier_path(line.points, line.origin)
        return """<path d="$path" stroke="$color" stroke-width="$(line.thickness)" fill="none"/>\n"""
    else
        return """<polyline points="$points_str" stroke="$color" stroke-width="$(line.thickness)" fill="none"/>\n"""
    end
end

function to_svg_element(polygon::Polygon)
    if !polygon.visible
        return ""
    end
    
    # Apply origin transformation
    points_str = join(["$(p[1]+polygon.origin[1]),$(p[2]+polygon.origin[2])" for p in polygon.points], " ")
    
    # Convert colors
    stroke = polygon.pattern == :None ? "none" : "rgb($(polygon.lineColor[1]),$(polygon.lineColor[2]),$(polygon.lineColor[3]))"
    fill = polygon.fillPattern == :None ? "none" : "rgb($(polygon.fillColor[1]),$(polygon.fillColor[2]),$(polygon.fillColor[3]))"
    
    return """<polygon points="$points_str" stroke="$stroke" stroke-width="$(polygon.lineThickness)" fill="$fill"/>\n"""
end

function to_svg_element(rect::Rectangle)
    if !rect.visible
        return ""
    end
    
    ((x1, y1), (x2, y2)) = rect.extent
    x = min(x1, x2) + rect.origin[1]
    y = min(y1, y2) + rect.origin[2]
    width = abs(x2 - x1)
    height = abs(y2 - y1)
    
    stroke = rect.pattern == :None ? "none" : "rgb($(rect.lineColor[1]),$(rect.lineColor[2]),$(rect.lineColor[3]))"
    fill = rect.fillPattern == :None ? "none" : "rgb($(rect.fillColor[1]),$(rect.fillColor[2]),$(rect.fillColor[3]))"
    
    rx = rect.radius > 0 ? "rx=\"$(rect.radius)\"" : ""
    
    return """<rect x="$x" y="$y" width="$width" height="$height" $rx stroke="$stroke" stroke-width="$(rect.lineThickness)" fill="$fill"/>\n"""
end

function to_svg_element(ellipse::Ellipse)
    if !ellipse.visible
        return ""
    end
    
    ((x1, y1), (x2, y2)) = ellipse.extent
    cx = (x1 + x2) / 2 + ellipse.origin[1]
    cy = (y1 + y2) / 2 + ellipse.origin[2]
    rx = abs(x2 - x1) / 2
    ry = abs(y2 - y1) / 2
    
    stroke = ellipse.pattern == :None ? "none" : "rgb($(ellipse.lineColor[1]),$(ellipse.lineColor[2]),$(ellipse.lineColor[3]))"
    fill = ellipse.fillPattern == :None ? "none" : "rgb($(ellipse.fillColor[1]),$(ellipse.fillColor[2]),$(ellipse.fillColor[3]))"
    
    return """<ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" stroke="$stroke" stroke-width="$(ellipse.lineThickness)" fill="$fill"/>\n"""
end

function to_svg_element(text::Text)
    if !text.visible
        return ""
    end
    
    ((x1, y1), (x2, y2)) = text.extent
    x = (x1 + x2) / 2 + text.origin[1]
    y = (y1 + y2) / 2 + text.origin[2]
    
    color = "rgb($(text.textColor[1]),$(text.textColor[2]),$(text.textColor[3]))"
    
    # Note: SVG text needs to be flipped back
    # We need to flip vertically around the text position
    font_size = text.fontSize > 0 ? text.fontSize : 12
    return """<text x="$x" y="$y" text-anchor="middle" fill="$color" font-size="$font_size" transform="scale(1,-1) translate(0,$(-y))">$(text.textString)</text>\n"""
end

function bezier_path(points::Vector{Tuple{Float64,Float64}}, origin::Tuple{Float64,Float64})
    if length(points) < 2
        return ""
    end
    
    path = "M $(points[1][1]+origin[1]),$(points[1][2]+origin[2])"
    
    # Simple Bezier approximation - can be improved
    for i in 2:length(points)
        p1 = points[i-1]
        p2 = points[i]
        
        # Control points at 1/3 and 2/3 of the way
        if i > 2
            cp1x = p1[1] + (p2[1] - points[i-2][1]) / 3
            cp1y = p1[2] + (p2[2] - points[i-2][2]) / 3
        else
            cp1x = p1[1] + (p2[1] - p1[1]) / 3
            cp1y = p1[2] + (p2[2] - p1[2]) / 3
        end
        
        if i < length(points)
            cp2x = p2[1] - (points[i+1][1] - p1[1]) / 3
            cp2y = p2[2] - (points[i+1][2] - p1[2]) / 3
        else
            cp2x = p2[1] - (p2[1] - p1[1]) / 3
            cp2y = p2[2] - (p2[2] - p1[2]) / 3
        end
        
        path *= " C $(cp1x+origin[1]),$(cp1y+origin[2]) $(cp2x+origin[1]),$(cp2y+origin[2]) $(p2[1]+origin[1]),$(p2[2]+origin[2])"
    end
    
    return path
end

# Main function
function main()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "input"
            help = "Input Modelica file or string containing annotation"
            required = true
        "-o", "--output"
            help = "Output SVG file"
            default = "output.svg"
        "-w", "--width"
            help = "SVG width in pixels"
            arg_type = Int
            default = 200
        "--height"
            help = "SVG height in pixels"
            arg_type = Int
            default = 200
        "--string"
            help = "Treat input as annotation string instead of file"
            action = :store_true
        "--skip-text"
            help = "Skip all text annotations"
            action = :store_true
        "--skip-parametric-text"
            help = "Skip parametric text annotations (those containing %)"
            action = :store_true
    end
    
    args = parse_args(s)
    
    # Read input
    if args["string"]
        content = args["input"]
    else
        content = read(args["input"], String)
    end
    
    # Parse annotation
    coord_system, graphics = parse_annotation(content)
    
    # Generate SVG
    svg = to_svg(coord_system, graphics; 
                 width=args["width"], 
                 height=args["height"],
                 skip_text=args["skip-text"],
                 skip_parametric_text=args["skip-parametric-text"])
    
    # Write output
    write(args["output"], svg)
    
    println("SVG generated: $(args["output"])")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end