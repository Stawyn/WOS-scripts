--[[
    Example usage of the Spherical Coordinates Module for Waste of Space
    
    This script demonstrates how to use the spherical_coordinates module
    for navigation, orientation, and coordinate conversion in WOS.
    
    Setup Required:
    1. Connect a Gyro to port 1 via cjoint
    2. Optional: Connect additional instruments for position reference
    
    Usage Examples:
    - Basic coordinate conversion
    - Real-time navigation with gyro
    - Relative positioning between objects
    - Trajectory calculations
]]

-- Import the spherical coordinates module
local SphericalCoords = require("spherical_coordinates")

-- Get WOS components
local gyro = GetPartFromPort(1, "Gyro") -- Gyro connected to port 1
local instrument = GetPart("Instrument") -- Optional: for position reference

-- Example configuration
local EXAMPLES = {
    BASIC_CONVERSION = true,
    REAL_TIME_TRACKING = true,
    NAVIGATION_SYSTEM = true,
    TRAJECTORY_CALC = true
}

-- Initialize the module
print("🚀 Initializing Spherical Coordinates Module...")
if not SphericalCoords.init(gyro) then
    error("Failed to initialize SphericalCoords module - check gyro connection")
end

-- Wait for calibration to complete
print("⏳ Waiting for gyro calibration...")
local calibration_timeout = 0
while not SphericalCoords.getStatus().calibrated and calibration_timeout < 100 do
    task.wait(0.1)
    calibration_timeout = calibration_timeout + 1
end

if not SphericalCoords.getStatus().calibrated then
    error("Gyro calibration failed - check gyro functionality")
end

print("✅ Module initialized and calibrated successfully!")
SphericalCoords.printStatus()

-- Example 1: Basic Coordinate Conversion
if EXAMPLES.BASIC_CONVERSION then
    print("\n=== Example 1: Basic Coordinate Conversion ===")
    
    -- Convert spherical to cartesian
    local spherical_coords = {
        {radius = 100, azimuth = 0, elevation = 0},     -- Point on X-axis
        {radius = 100, azimuth = 90, elevation = 0},    -- Point on Y-axis  
        {radius = 100, azimuth = 0, elevation = 90},    -- Point on Z-axis
        {radius = 150, azimuth = 45, elevation = 30},   -- Arbitrary point
    }
    
    print("Spherical → Cartesian conversions:")
    for i, coord in ipairs(spherical_coords) do
        local cartesian = SphericalCoords.sphericalToCartesian(coord.radius, coord.azimuth, coord.elevation)
        if cartesian then
            print(string.format("  %d. (r=%.1f, θ=%.1f°, φ=%.1f°) → (x=%.2f, y=%.2f, z=%.2f)", 
                i, coord.radius, coord.azimuth, coord.elevation, 
                cartesian.x, cartesian.y, cartesian.z))
        end
    end
    
    -- Convert cartesian back to spherical
    print("\nCartesian → Spherical conversions:")
    local cartesian_coords = {
        {x = 100, y = 0, z = 0},
        {x = 0, y = 100, z = 0},
        {x = 0, y = 0, z = 100},
        {x = 50, y = 50, z = 86.6},
    }
    
    for i, coord in ipairs(cartesian_coords) do
        local spherical = SphericalCoords.cartesianToSpherical(coord.x, coord.y, coord.z)
        if spherical then
            print(string.format("  %d. (x=%.1f, y=%.1f, z=%.1f) → (r=%.2f, θ=%.1f°, φ=%.1f°)", 
                i, coord.x, coord.y, coord.z, 
                spherical.radius, spherical.azimuth, spherical.elevation))
        end
    end
end

-- Example 2: Real-time Tracking with Gyro
if EXAMPLES.REAL_TIME_TRACKING then
    print("\n=== Example 2: Real-time Gyro Tracking ===")
    print("Tracking orientation for 10 seconds...")
    
    local start_time = os.time()
    local sample_count = 0
    
    task.spawn(function()
        while os.time() - start_time < 10 do
            local coords = SphericalCoords.getSphericalFromGyro(100) -- Using radius of 100
            if coords then
                sample_count = sample_count + 1
                if sample_count % 10 == 0 then -- Print every 10th sample
                    print(string.format("  Sample %d: θ=%.1f°, φ=%.1f° → (x=%.1f, y=%.1f, z=%.1f)", 
                        sample_count, coords.azimuth, coords.elevation, coords.x, coords.y, coords.z))
                end
            end
            task.wait(0.1)
        end
        print(string.format("Tracking complete. %d samples collected.", sample_count))
    end)
    
    task.wait(11) -- Wait for tracking to complete
end

-- Example 3: Navigation System
if EXAMPLES.NAVIGATION_SYSTEM then
    print("\n=== Example 3: Navigation System ===")
    
    -- Simulate some target positions
    local targets = {
        {name = "Station Alpha", x = 500, y = 300, z = 100},
        {name = "Mining Outpost", x = -200, y = 800, z = -150},
        {name = "Fuel Depot", x = 0, y = 0, z = 1000},
    }
    
    -- Current position (you could get this from an instrument)
    local current_pos = {x = 0, y = 0, z = 0}
    if instrument then
        local pos_reading = instrument:GetReading("Position")
        if pos_reading then
            current_pos = pos_reading
        end
    end
    
    print(string.format("Current position: (%.1f, %.1f, %.1f)", current_pos.x, current_pos.y, current_pos.z))
    print("Navigation targets:")
    
    for _, target in ipairs(targets) do
        local relative_pos = SphericalCoords.getRelativePosition(target, current_pos)
        if relative_pos then
            print(string.format("  %s: Distance=%.1f, Bearing=%.1f°, Elevation=%.1f°", 
                target.name, relative_pos.radius, relative_pos.azimuth, relative_pos.elevation))
        end
    end
end

-- Example 4: Trajectory Calculations
if EXAMPLES.TRAJECTORY_CALC then
    print("\n=== Example 4: Trajectory Calculations ===")
    
    -- Calculate trajectory points for a curved path
    local function calculateTrajectory(start_pos, end_pos, segments)
        local trajectory = {}
        
        for i = 0, segments do
            local t = i / segments
            -- Simple linear interpolation (you could use more complex curves)
            local point = {
                x = start_pos.x + t * (end_pos.x - start_pos.x),
                y = start_pos.y + t * (end_pos.y - start_pos.y),
                z = start_pos.z + t * (end_pos.z - start_pos.z)
            }
            
            -- Convert to spherical relative to start position
            local spherical = SphericalCoords.getRelativePosition(point, start_pos)
            if spherical then
                table.insert(trajectory, {
                    segment = i,
                    cartesian = point,
                    spherical = spherical
                })
            end
        end
        
        return trajectory
    end
    
    local start_pos = {x = 0, y = 0, z = 0}
    local end_pos = {x = 1000, y = 500, z = 200}
    local trajectory = calculateTrajectory(start_pos, end_pos, 5)
    
    print("Trajectory from (0,0,0) to (1000,500,200):")
    for _, point in ipairs(trajectory) do
        print(string.format("  Segment %d: (%.1f,%.1f,%.1f) - Distance=%.1f, Bearing=%.1f°, Elevation=%.1f°",
            point.segment, 
            point.cartesian.x, point.cartesian.y, point.cartesian.z,
            point.spherical.radius, point.spherical.azimuth, point.spherical.elevation))
    end
end

-- Continuous monitoring loop (optional)
print("\n=== Continuous Monitoring ===")
print("Starting continuous monitoring... (Press Ctrl+C to stop)")
print("This will track gyro orientation and provide navigation data.")

local monitoring_enabled = true
local last_status_time = 0

task.spawn(function()
    while monitoring_enabled do
        -- Update orientation every second
        local current_time = os.time()
        
        -- Get current orientation from gyro
        local orientation = SphericalCoords.getCorrectedOrientation()
        if orientation then
            -- Convert to compass bearing for easier navigation
            local bearing = math.floor((math.deg(orientation.y) + 360) % 360)
            local pitch = math.floor(math.deg(orientation.x))
            
            -- Print status every 5 seconds
            if current_time - last_status_time >= 5 then
                print(string.format("🧭 Heading: %d° | Pitch: %d° | Time: %s", 
                    bearing, pitch, os.date("%H:%M:%S", current_time)))
                last_status_time = current_time
            end
        end
        
        task.wait(1)
    end
end)

-- Keep the script running
print("✅ All examples completed successfully!")
print("📊 Module is now running in continuous monitoring mode.")
print("🎯 Use the SphericalCoords functions in your own navigation scripts.")

-- Example of how to use in a ship control system
--[[
Example ship autopilot integration:

local target_position = {x = 1000, y = 500, z = 200}
local current_position = instrument:GetReading("Position")

-- Calculate navigation bearing
local nav_data = SphericalCoords.getRelativePosition(target_position, current_position)
if nav_data then
    local required_bearing = nav_data.azimuth
    local required_elevation = nav_data.elevation
    local distance = nav_data.radius
    
    -- Point gyro at target
    local target_world_pos = Vector3.new(target_position.x, target_position.y, target_position.z)
    gyro:PointAt(target_world_pos)
    
    print(string.format("Navigate to target: %.1f km at bearing %.1f°", distance/1000, required_bearing))
end
]]