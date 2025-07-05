# Gyro Coordinate Converter for Waste of Space

This repository contains scripts for converting spherical coordinates to Cartesian coordinates using gyroscope data in the Waste of Space game.

## Files

- **`gyro_coordinate_converter.txt`** - Full-featured modular coordinate conversion system
- **`gyro_coordinate_example.txt`** - Examples and usage demonstrations
- **`s13.txt`** - Simple standalone coordinate converter (recommended for beginners)

## Quick Start

### Basic Usage (s13.txt)

1. Connect a gyroscope to port 1 of your ship using a cjoint
2. Copy the contents of `s13.txt` into a MicroController
3. Run the script
4. The script will auto-calibrate after 3 seconds
5. Monitor the coordinate output every 5 seconds

### Features

#### Core Functionality
- ✅ Reads gyroscope pitch, yaw, and roll data
- ✅ Converts spherical coordinates to Cartesian (X, Y, Z)
- ✅ Automatic calibration system for reference point
- ✅ Angle normalization (-180° to 180°)
- ✅ Formatted coordinate output
- ✅ Filtering for smooth readings

#### Mathematical Conversion
The script implements the standard spherical to Cartesian conversion formulas:
- `X = r * sin(θ) * cos(φ)`
- `Y = r * sin(θ) * sin(φ)`
- `Z = r * cos(θ)`

Where:
- `r` = radius/distance (default: 1 for unit vectors)
- `θ` = polar angle (pitch)
- `φ` = azimuthal angle (yaw)

## Setup Instructions

### Hardware Requirements
1. **Gyroscope** - Connect to port 1 via cjoint
2. **MicroController** - To run the script
3. **Power source** - To power the components

### Software Setup
1. Place a MicroController on your ship
2. Connect the gyroscope to port 1 of the MicroController using a cjoint
3. Copy one of the script files into the MicroController
4. Click "Run" on the MicroController

## Usage Examples

### Example 1: Basic Monitoring
```lua
-- The script will automatically:
-- 1. Calibrate the reference point
-- 2. Display raw gyro readings
-- 3. Show relative angles from calibration
-- 4. Convert to Cartesian coordinates
-- 5. Update every 5 seconds
```

### Example 2: Integration with Other Systems
```lua
-- Get direction vector for pointing systems
local direction = GetCartesianCoordinates(1, true)
if direction then
    -- Use direction.x, direction.y, direction.z for:
    -- - Navigation
    -- - Targeting
    -- - Ship alignment
    -- - Orientation tracking
end
```

### Example 3: Custom Distance Scaling
```lua
-- Get navigation vector at specific distance
local nav_coords = GetCartesianCoordinates(100, true) -- 100 unit distance
-- Results in coordinates scaled to 100 units from origin
```

## Configuration Options

### In s13.txt (Simple Version)
- **Calibration**: Automatic on startup
- **Update Rate**: 5 seconds (modify `task.wait(5)`)
- **Precision**: 3 decimal places

### In gyro_coordinate_converter.txt (Advanced Version)
```lua
local CONFIG = {
    calibration = { pitch = 0, yaw = 0, roll = 0 },
    filtering = {
        enabled = true,
        smoothing_factor = 0.8,  -- 0.0 to 1.0
        history_size = 5
    },
    precision = 3,  -- decimal places
    default_radius = 1
}
```

## API Reference

### Core Functions

#### `Calibrate()`
Sets current gyro position as reference point (0,0,0).
- **Returns**: `true` if successful, `false` if failed
- **Usage**: Call when ship is in desired reference orientation

#### `GetCartesianCoordinates(radius, use_relative)`
Converts current gyro reading to Cartesian coordinates.
- **radius** (optional): Distance scale (default: 1)
- **use_relative** (optional): Use calibrated reference (default: false)
- **Returns**: `{x, y, z, magnitude}` or `nil` if failed

#### `ReadGyro()`
Reads raw gyroscope data.
- **Returns**: `{pitch, yaw, roll}` or `nil` if failed

#### `NormalizeAngle(angle)`
Normalizes angle to -180° to 180° range.
- **angle**: Angle in degrees
- **Returns**: Normalized angle

### Utility Functions

#### `FormatCoords(coords, label)`
Formats coordinates for display.
- **coords**: Coordinate table `{x, y, z}`
- **label**: Optional label string
- **Returns**: Formatted string

#### `PrintStatus()`
Prints comprehensive coordinate status to console.

## Integration Examples

### With Pointing Systems (like s1.txt)
```lua
-- Get direction vector
local direction = GetCartesianCoordinates(100, true)
if direction then
    local target_pos = Vector3.new(direction.x, direction.y, direction.z)
    gyro:PointAt(target_pos)
end
```

### With Navigation Systems
```lua
-- Calculate navigation waypoint
local nav_distance = 500
local nav_vector = GetCartesianCoordinates(nav_distance, true)
-- Use nav_vector for autopilot or course correction
```

### With Reactor Systems (like s9.txt)
```lua
-- Use orientation for reactor selection/control
local direction = GetCartesianCoordinates(1, true)
local reactor_index = math.floor(math.abs(direction.x * #reactors)) + 1
-- Control reactor based on ship orientation
```

## Troubleshooting

### Common Issues

1. **"Failed to read gyro"**
   - Check gyroscope connection to port 1
   - Verify cjoint is properly attached
   - Ensure gyroscope is powered

2. **"Calibration failed"**
   - Gyroscope may not be responding
   - Try reconnecting the gyroscope
   - Check power supply

3. **Erratic readings**
   - Enable filtering in advanced version
   - Increase smoothing_factor (0.8-0.9)
   - Check for interference from other parts

4. **Coordinates not updating**
   - Verify script is running (check console output)
   - Ensure ship is actually moving/rotating
   - Check if gyroscope is functional

### Performance Tips

1. **For high-frequency updates**: Reduce `task.wait()` time
2. **For smoother readings**: Enable filtering in advanced version
3. **For better accuracy**: Calibrate in stable, level position
4. **For integration**: Use the modular version (gyro_coordinate_converter.txt)

## Technical Notes

### Coordinate System
- **X-axis**: Forward/backward relative to calibration
- **Y-axis**: Left/right relative to calibration  
- **Z-axis**: Up/down relative to calibration
- **Origin**: Calibration point (0,0,0)

### Angle Conventions
- **Pitch**: Rotation around X-axis (nose up/down)
- **Yaw**: Rotation around Y-axis (turning left/right)
- **Roll**: Rotation around Z-axis (banking left/right)

### Filtering Algorithm
The advanced version uses exponential smoothing:
```
smoothed_value = current * (1 - factor) + average * factor
```
Where factor ranges from 0.0 (no smoothing) to 1.0 (maximum smoothing).

## Version History

- **v1.0**: Initial implementation with basic coordinate conversion
- **v1.1**: Added calibration system and angle normalization
- **v1.2**: Added filtering and smoothing options
- **v1.3**: Created simplified standalone version (s13.txt)

## License

This code is provided as-is for use in Waste of Space. Feel free to modify and integrate into your own scripts.