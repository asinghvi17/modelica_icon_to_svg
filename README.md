# Modelica2SVG

A Julia script to convert Modelica graphical annotations to SVG format.

## Overview

Modelica2SVG parses Modelica Icon annotations and converts them into scalable vector graphics (SVG). This tool is useful for:
- Generating visual documentation of Modelica components
- Creating icon libraries from Modelica packages
- Extracting graphics for use in other applications
- Batch processing entire Modelica libraries

## Features

- Parses Modelica Icon annotations with coordinate systems
- Supports multiple graphical elements:
  - **Line**: With points, color, thickness, and Bezier curve smoothing
  - **Polygon**: With fill colors, line colors, and patterns
  - **Rectangle**: With extent, colors, and corner radius
  - **Ellipse**: With extent, colors, and angles
  - **Text**: With positioning, color, and font properties
- Handles coordinate system transformations (Modelica to SVG)
- Command-line options for filtering text elements
- Batch processing capabilities for entire libraries

## Installation

Requires Julia and the ArgParse package:

```bash
julia -e 'import Pkg; Pkg.add("ArgParse")'
```

## Usage

### Basic Usage

Convert a Modelica file to SVG:

```bash
julia modelica2svg.jl input.mo -o output.svg
```

Convert an annotation string directly:

```bash
julia modelica2svg.jl "annotation(Icon(graphics={...}))" --string -o output.svg
```

### Command Line Options

- `-o, --output`: Output SVG file (default: output.svg)
- `-w, --width`: SVG width in pixels (default: 200)
- `--height`: SVG height in pixels (default: 200)
- `--string`: Treat input as annotation string instead of file
- `--skip-text`: Skip all text annotations
- `--skip-parametric-text`: Skip parametric text annotations (those containing %)

### Examples

Skip all text annotations:
```bash
julia modelica2svg.jl MyComponent.mo -o icon_no_text.svg --skip-text
```

Skip only parametric text (like %name, %parameter):
```bash
julia modelica2svg.jl MyComponent.mo -o icon_no_params.svg --skip-parametric-text
```

## Batch Processing

For processing multiple files, see the included `process_thermal.jl` script as an example:

```julia
include("modelica2svg.jl")

# Process a single file
coord_system, graphics = parse_annotation(content)
svg = to_svg(coord_system, graphics; width=200, height=200, skip_text=true)
```

## Examples

The `test_examples/` directory contains sample Modelica files:
- `thermal_icon.mo` - Thermal package icon with Bezier curves
- `simple_shapes.mo` - Basic shapes with colors
- `parametric_text.mo` - Text annotation examples

## Converting to PNG

To convert generated SVGs to PNG format (requires ImageMagick):

```bash
magick output.svg output.png
```

## Supported Modelica Elements

### Graphical Elements
- **Line**: Points array, color, thickness, smooth curves (Bezier)
- **Polygon**: Points array, fill color, line color, fill patterns
- **Rectangle**: Extent, fill color, line color, corner radius
- **Ellipse**: Extent, fill color, line color, start/end angles
- **Text**: Extent, text string, color, font properties

### Coordinate Systems
- Automatic transformation from Modelica's center-based coordinates to SVG's top-left system
- Preserves aspect ratios and scaling

## Limitations

- Only supports Icon annotations (not Diagram)
- Limited pattern support (only Solid/None fill patterns)
- No bitmap image support
- No DynamicSelect support
- Text rotation not fully implemented

## Testing with Modelica Standard Library

The tool has been tested with the Modelica Standard Library thermal components:

```bash
# Clone MSL
git clone --depth 1 https://github.com/modelica/ModelicaStandardLibrary.git

# Process thermal components
julia process_thermal.jl
```

Successfully processes components from:
- Thermal.HeatTransfer
- Thermal.FluidHeatFlow

## License

This tool is provided as-is for converting Modelica graphical annotations to SVG format.