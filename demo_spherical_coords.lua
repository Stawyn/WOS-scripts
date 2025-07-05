--[[
    Quick Demo Script for Spherical Coordinates Module
    
    This script provides a quick demonstration of the module's capabilities
    without requiring actual WOS hardware. Perfect for testing and demonstration.
]]

print("🚀 Spherical Coordinates Module - Quick Demo")
print("=" .. string.rep("=", 50))

-- Run the mathematical validation first
print("Running mathematical validation tests...")
local test_passed = require("test_spherical_coords")

if test_passed then
    print("\n✅ All mathematical functions validated successfully!")
else
    print("\n❌ Mathematical validation failed!")
    return
end

-- Demonstrate core functionality
local SphericalCoords = require("spherical_coordinates")

print("\n🧮 Core Conversion Examples:")
print("-" .. string.rep("-", 30))

-- Example conversions
local examples = {
    {desc = "Point on X-axis", r = 100, a = 0, e = 0},
    {desc = "Point on Y-axis", r = 100, a = 90, e = 0},
    {desc = "Point on Z-axis", r = 100, a = 0, e = 90},
    {desc = "45° diagonal", r = 100, a = 45, e = 45},
    {desc = "Space station", r = 1500, a = 135, e = -15},
}

for _, ex in ipairs(examples) do
    local cart = SphericalCoords.sphericalToCartesian(ex.r, ex.a, ex.e)
    local sphere = SphericalCoords.cartesianToSpherical(cart.x, cart.y, cart.z)
    
    print(string.format("%s:", ex.desc))
    print(string.format("  Spherical: r=%.1f, θ=%.1f°, φ=%.1f°", ex.r, ex.a, ex.e))
    print(string.format("  Cartesian: x=%.1f, y=%.1f, z=%.1f", cart.x, cart.y, cart.z))
    print(string.format("  Verified:  r=%.1f, θ=%.1f°, φ=%.1f°", sphere.radius, sphere.azimuth, sphere.elevation))
    print()
end

print("🎯 Navigation Examples:")
print("-" .. string.rep("-", 20))

-- Navigation examples
local ship_pos = {x = 0, y = 0, z = 0}
local targets = {
    {name = "Mining Station", x = 1000, y = 500, z = 200},
    {name = "Fuel Depot", x = -800, y = 1200, z = -300},
    {name = "Jump Gate", x = 0, y = 0, z = 2000},
}

for _, target in ipairs(targets) do
    local nav = SphericalCoords.getRelativePosition(target, ship_pos)
    local distance_km = nav.radius / 1000
    
    print(string.format("%s:", target.name))
    print(string.format("  Position: (%.0f, %.0f, %.0f)", target.x, target.y, target.z))
    print(string.format("  Distance: %.1f km", distance_km))
    print(string.format("  Bearing:  %.1f°", nav.azimuth))
    print(string.format("  Elevation: %.1f°", nav.elevation))
    
    -- Convert bearing to cardinal direction
    local cardinal = ""
    if nav.azimuth >= 337.5 or nav.azimuth < 22.5 then cardinal = "N"
    elseif nav.azimuth < 67.5 then cardinal = "NE"
    elseif nav.azimuth < 112.5 then cardinal = "E"
    elseif nav.azimuth < 157.5 then cardinal = "SE"
    elseif nav.azimuth < 202.5 then cardinal = "S"
    elseif nav.azimuth < 247.5 then cardinal = "SW"
    elseif nav.azimuth < 292.5 then cardinal = "W"
    else cardinal = "NW" end
    
    local elevation_desc = ""
    if nav.elevation > 30 then elevation_desc = " (high)"
    elseif nav.elevation < -30 then elevation_desc = " (low)"
    else elevation_desc = " (level)" end
    
    print(string.format("  Direction: %s%s", cardinal, elevation_desc))
    print()
end

print("📈 Trajectory Calculation Example:")
print("-" .. string.rep("-", 35))

-- Trajectory example
local start = {x = 0, y = 0, z = 0}
local destination = {x = 2000, y = 1000, z = 500}
local waypoints = 5

print(string.format("Trajectory from (%.0f,%.0f,%.0f) to (%.0f,%.0f,%.0f):", 
    start.x, start.y, start.z, destination.x, destination.y, destination.z))

for i = 0, waypoints do
    local t = i / waypoints
    local point = {
        x = start.x + t * (destination.x - start.x),
        y = start.y + t * (destination.y - start.y),
        z = start.z + t * (destination.z - start.z)
    }
    
    local nav = SphericalCoords.getRelativePosition(point, start)
    local progress = i * (100 / waypoints)
    
    print(string.format("  Waypoint %d (%3.0f%%): (%.0f,%.0f,%.0f) - %.1f km at %.1f°", 
        i, progress, point.x, point.y, point.z, nav.radius/1000, nav.azimuth))
end

print("\n🎮 Game Integration Examples:")
print("-" .. string.rep("-", 28))

print("Example autopilot code:")
print([[
-- Autopilot example
local gyro = GetPartFromPort(1, "Gyro")
local instrument = GetPart("Instrument")
SphericalCoords.init(gyro)

local target = {x = 1000, y = 500, z = 200}
local current = instrument:GetReading("Position")
local nav = SphericalCoords.getRelativePosition(target, current)

-- Point toward target
gyro:PointAt(Vector3.new(target.x, target.y, target.z))

print("Navigate " .. nav.radius/1000 .. " km at bearing " .. nav.azimuth .. "°")
]])

print("\nExample distance calculation:")
print([[
-- Calculate distance to multiple targets
local targets = {station1, station2, fuelDepot}
for _, target in ipairs(targets) do
    local nav = SphericalCoords.getRelativePosition(target, current_pos)
    print(target.name .. ": " .. nav.radius/1000 .. " km away")
end
]])

print("\n🔧 Module Configuration:")
print("-" .. string.rep("-", 23))

print("Available configuration options:")
print("• Debug mode: SphericalCoords.setDebugMode(true/false)")
print("• Noise filter: SphericalCoords.setNoiseFilterAlpha(0.0-1.0)")
print("• Calibration samples: Modify CONFIG.CALIBRATION_SAMPLES in module")
print("• Drift correction interval: Modify CONFIG.DRIFT_CORRECTION_INTERVAL")

print("\n✨ Summary:")
print("-" .. string.rep("-", 10))
print("The Spherical Coordinates Module provides:")
print("• Accurate coordinate conversions (100% test pass rate)")
print("• Real-time gyro integration with calibration")
print("• Noise filtering and drift compensation")
print("• Navigation and trajectory calculation functions")
print("• Comprehensive error handling and logging")
print("• Easy integration with WOS ship systems")

print("\n🚀 Ready for use in Waste of Space!")
print("📖 See README_spherical_coords.md for complete documentation")
print("🔧 See spherical_coords_example.lua for advanced examples")

print("\n" .. "=" .. string.rep("=", 50))
print("Demo complete! Module is ready for deployment.")