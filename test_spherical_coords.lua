--[[
    Test Script for Spherical Coordinates Module
    
    This script tests the mathematical accuracy of the coordinate conversion functions
    without requiring actual WOS hardware (gyro, etc.)
    
    Run this to verify the module's core functionality.
]]

-- Mock WOS functions for testing
local function mockGetPartFromPort()
    return {
        GetReading = function()
            return {
                Orientation = {
                    X = math.random() * 0.1 - 0.05, -- Small random values to simulate gyro
                    Y = math.random() * 0.1 - 0.05,
                    Z = math.random() * 0.1 - 0.05
                }
            }
        end
    }
end

-- Set up test environment
_G.GetPartFromPort = mockGetPartFromPort
_G.task = {
    wait = function(t) 
        -- Simulate wait without actually waiting in tests
        return
    end,
    spawn = function(func)
        -- Execute immediately for tests
        func()
    end
}
_G.print = print
_G.os = os
_G.math = math

-- Import the module
local SphericalCoords = require("spherical_coordinates")

-- Test results tracking
local tests_passed = 0
local tests_failed = 0
local test_details = {}

-- Test helper functions
local function assertAlmostEqual(actual, expected, tolerance, test_name)
    tolerance = tolerance or 0.001
    local diff = math.abs(actual - expected)
    if diff <= tolerance then
        tests_passed = tests_passed + 1
        table.insert(test_details, "✅ " .. test_name)
        return true
    else
        tests_failed = tests_failed + 1
        table.insert(test_details, string.format("❌ %s: Expected %.6f, got %.6f (diff: %.6f)", 
            test_name, expected, actual, diff))
        return false
    end
end

local function test_spherical_to_cartesian()
    print("Testing spherical to cartesian conversion...")
    
    -- Test case 1: Point on X-axis
    local result = SphericalCoords.sphericalToCartesian(100, 0, 0)
    assertAlmostEqual(result.x, 100, 0.001, "X-axis point X coordinate")
    assertAlmostEqual(result.y, 0, 0.001, "X-axis point Y coordinate")
    assertAlmostEqual(result.z, 0, 0.001, "X-axis point Z coordinate")
    
    -- Test case 2: Point on Y-axis
    result = SphericalCoords.sphericalToCartesian(100, 90, 0)
    assertAlmostEqual(result.x, 0, 0.001, "Y-axis point X coordinate")
    assertAlmostEqual(result.y, 100, 0.001, "Y-axis point Y coordinate")
    assertAlmostEqual(result.z, 0, 0.001, "Y-axis point Z coordinate")
    
    -- Test case 3: Point on Z-axis
    result = SphericalCoords.sphericalToCartesian(100, 0, 90)
    assertAlmostEqual(result.x, 0, 0.001, "Z-axis point X coordinate")
    assertAlmostEqual(result.y, 0, 0.001, "Z-axis point Y coordinate")
    assertAlmostEqual(result.z, 100, 0.001, "Z-axis point Z coordinate")
    
    -- Test case 4: Known point (45°, 45°)
    result = SphericalCoords.sphericalToCartesian(100, 45, 45)
    local expected_x = 100 * math.cos(math.rad(45)) * math.cos(math.rad(45))
    local expected_y = 100 * math.cos(math.rad(45)) * math.sin(math.rad(45))
    local expected_z = 100 * math.sin(math.rad(45))
    
    assertAlmostEqual(result.x, expected_x, 0.001, "45°/45° point X coordinate")
    assertAlmostEqual(result.y, expected_y, 0.001, "45°/45° point Y coordinate")
    assertAlmostEqual(result.z, expected_z, 0.001, "45°/45° point Z coordinate")
end

local function test_cartesian_to_spherical()
    print("Testing cartesian to spherical conversion...")
    
    -- Test case 1: Point on X-axis
    local result = SphericalCoords.cartesianToSpherical(100, 0, 0)
    assertAlmostEqual(result.radius, 100, 0.001, "X-axis point radius")
    assertAlmostEqual(result.azimuth, 0, 0.001, "X-axis point azimuth")
    assertAlmostEqual(result.elevation, 0, 0.001, "X-axis point elevation")
    
    -- Test case 2: Point on Y-axis
    result = SphericalCoords.cartesianToSpherical(0, 100, 0)
    assertAlmostEqual(result.radius, 100, 0.001, "Y-axis point radius")
    assertAlmostEqual(result.azimuth, 90, 0.001, "Y-axis point azimuth")
    assertAlmostEqual(result.elevation, 0, 0.001, "Y-axis point elevation")
    
    -- Test case 3: Point on Z-axis
    result = SphericalCoords.cartesianToSpherical(0, 0, 100)
    assertAlmostEqual(result.radius, 100, 0.001, "Z-axis point radius")
    assertAlmostEqual(result.elevation, 90, 0.001, "Z-axis point elevation")
    
    -- Test case 4: Known point
    local x, y, z = 50, 50, 70.71
    result = SphericalCoords.cartesianToSpherical(x, y, z)
    local expected_radius = math.sqrt(x*x + y*y + z*z)
    local expected_azimuth = math.deg(math.atan2(y, x))
    local expected_elevation = math.deg(math.asin(z / expected_radius))
    
    assertAlmostEqual(result.radius, expected_radius, 0.001, "Complex point radius")
    assertAlmostEqual(result.azimuth, expected_azimuth, 0.001, "Complex point azimuth")
    assertAlmostEqual(result.elevation, expected_elevation, 0.001, "Complex point elevation")
end

local function test_round_trip_conversion()
    print("Testing round-trip conversion accuracy...")
    
    local test_points = {
        {r = 100, a = 0, e = 0},
        {r = 150, a = 45, e = 30},
        {r = 200, a = 180, e = -45},
        {r = 75, a = 270, e = 60},
        {r = 50, a = 135, e = -30},
    }
    
    for i, point in ipairs(test_points) do
        -- Convert spherical → cartesian → spherical
        local cartesian = SphericalCoords.sphericalToCartesian(point.r, point.a, point.e)
        local spherical = SphericalCoords.cartesianToSpherical(cartesian.x, cartesian.y, cartesian.z)
        
        assertAlmostEqual(spherical.radius, point.r, 0.001, 
            string.format("Round-trip test %d radius", i))
        assertAlmostEqual(spherical.azimuth, point.a, 0.001, 
            string.format("Round-trip test %d azimuth", i))
        assertAlmostEqual(spherical.elevation, point.e, 0.001, 
            string.format("Round-trip test %d elevation", i))
    end
end

local function test_edge_cases()
    print("Testing edge cases...")
    
    -- Test origin point
    local result = SphericalCoords.cartesianToSpherical(0, 0, 0)
    assertAlmostEqual(result.radius, 0, 0.001, "Origin radius")
    assertAlmostEqual(result.azimuth, 0, 0.001, "Origin azimuth")
    assertAlmostEqual(result.elevation, 0, 0.001, "Origin elevation")
    
    -- Test negative coordinates
    result = SphericalCoords.cartesianToSpherical(-100, -100, 0)
    assertAlmostEqual(result.radius, math.sqrt(20000), 0.001, "Negative coords radius")
    assertAlmostEqual(result.azimuth, 225, 0.001, "Negative coords azimuth")
    
    -- Test large coordinates
    result = SphericalCoords.sphericalToCartesian(10000, 0, 0)
    assertAlmostEqual(result.x, 10000, 0.001, "Large coordinate X")
    
    -- Test invalid inputs (should handle gracefully)
    result = SphericalCoords.sphericalToCartesian(nil, 0, 0)
    if result == nil then
        tests_passed = tests_passed + 1
        table.insert(test_details, "✅ Nil radius handled correctly")
    else
        tests_failed = tests_failed + 1
        table.insert(test_details, "❌ Nil radius should return nil")
    end
end

local function test_relative_position()
    print("Testing relative position calculations...")
    
    local pos1 = {x = 100, y = 100, z = 100}
    local pos2 = {x = 200, y = 150, z = 120}
    
    local relative = SphericalCoords.getRelativePosition(pos2, pos1)
    
    -- Calculate expected values
    local dx, dy, dz = pos2.x - pos1.x, pos2.y - pos1.y, pos2.z - pos1.z
    local expected_radius = math.sqrt(dx*dx + dy*dy + dz*dz)
    local expected_azimuth = math.deg(math.atan2(dy, dx))
    local expected_elevation = math.deg(math.asin(dz / expected_radius))
    
    assertAlmostEqual(relative.radius, expected_radius, 0.001, "Relative position radius")
    assertAlmostEqual(relative.azimuth, expected_azimuth, 0.001, "Relative position azimuth")
    assertAlmostEqual(relative.elevation, expected_elevation, 0.001, "Relative position elevation")
end

-- Run all tests
print("🧪 Starting Spherical Coordinates Module Tests")
print("==============================================")

-- Disable debug mode for cleaner test output
SphericalCoords.setDebugMode(false)

-- Initialize with mock gyro
local mock_gyro = mockGetPartFromPort()
SphericalCoords.init(mock_gyro)

-- Run test suites
test_spherical_to_cartesian()
test_cartesian_to_spherical()
test_round_trip_conversion()
test_edge_cases()
test_relative_position()

-- Print results
print("\n==============================================")
print("🧪 Test Results Summary")
print("==============================================")

for _, detail in ipairs(test_details) do
    print(detail)
end

print(string.format("\n📊 Tests Passed: %d", tests_passed))
print(string.format("❌ Tests Failed: %d", tests_failed))
print(string.format("📈 Success Rate: %.1f%%", (tests_passed / (tests_passed + tests_failed)) * 100))

if tests_failed == 0 then
    print("\n🎉 All tests passed! The module is working correctly.")
else
    print(string.format("\n⚠️  %d test(s) failed. Please review the implementation.", tests_failed))
end

print("\n==============================================")
return tests_failed == 0