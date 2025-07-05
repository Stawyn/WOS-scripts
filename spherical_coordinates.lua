--[[
    Spherical to Cartesian Coordinate Conversion Module for Waste of Space
    
    This module provides functions to convert between spherical and Cartesian coordinates
    using gyro data for navigation and orientation in space.
    
    Author: WOS-scripts
    Version: 1.0
    
    Features:
    - Spherical to Cartesian coordinate conversion
    - Gyro calibration and drift compensation
    - Noise filtering for sensor data
    - Real-time position tracking
    - Logging and debugging capabilities
    
    Usage:
    local coords = require("spherical_coordinates")
    local gyro = GetPartFromPort(1, "Gyro")
    coords.init(gyro)
    local cartesian = coords.sphericalToCartesian(100, 45, 30)
]]

local SphericalCoords = {}

-- Configuration constants
local CONFIG = {
    CALIBRATION_SAMPLES = 50,           -- Number of samples for gyro calibration
    DRIFT_CORRECTION_INTERVAL = 60,     -- Seconds between drift corrections
    NOISE_FILTER_ALPHA = 0.8,           -- Low-pass filter coefficient (0-1)
    DEBUG_MODE = true,                  -- Enable/disable debug logging
    MAX_DRIFT_THRESHOLD = 5.0,          -- Maximum allowed drift in degrees
}

-- Module state
local state = {
    gyro = nil,
    calibrated = false,
    calibration_offset = {x = 0, y = 0, z = 0},
    drift_compensation = {x = 0, y = 0, z = 0},
    last_drift_correction = 0,
    filtered_orientation = {x = 0, y = 0, z = 0},
    raw_readings = {},
    initialized = false
}

-- Utility functions
local function degToRad(degrees)
    return degrees * (math.pi / 180)
end

local function radToDeg(radians)
    return radians * (180 / math.pi)
end

local function clampAngle(angle)
    while angle > 360 do angle = angle - 360 end
    while angle < 0 do angle = angle + 360 end
    return angle
end

-- Logging function
local function log(message, level)
    if CONFIG.DEBUG_MODE then
        local timestamp = os.time()
        local prefix = level and "[" .. level .. "]" or "[INFO]"
        print(string.format("[SphericalCoords %d] %s %s", timestamp, prefix, message))
    end
end

-- Error handling wrapper
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        log("Error: " .. tostring(result), "ERROR")
        return nil
    end
    return result
end

-- Gyro calibration functions
function SphericalCoords.calibrateGyro()
    if not state.gyro then
        log("Cannot calibrate: Gyro not initialized", "ERROR")
        return false
    end
    
    log("Starting gyro calibration...")
    local sum_x, sum_y, sum_z = 0, 0, 0
    local valid_samples = 0
    
    for i = 1, CONFIG.CALIBRATION_SAMPLES do
        local reading = safeCall(function() 
            return state.gyro:GetReading() 
        end)
        
        if reading and reading.Orientation then
            local orient = reading.Orientation
            sum_x = sum_x + orient.X
            sum_y = sum_y + orient.Y
            sum_z = sum_z + orient.Z
            valid_samples = valid_samples + 1
        end
        
        task.wait(0.1) -- Small delay between samples
    end
    
    if valid_samples < CONFIG.CALIBRATION_SAMPLES * 0.8 then
        log("Calibration failed: Insufficient valid samples", "ERROR")
        return false
    end
    
    -- Calculate average offset
    state.calibration_offset = {
        x = sum_x / valid_samples,
        y = sum_y / valid_samples,
        z = sum_z / valid_samples
    }
    
    state.calibrated = true
    log(string.format("Calibration complete. Offset: X=%.2f, Y=%.2f, Z=%.2f", 
        state.calibration_offset.x, state.calibration_offset.y, state.calibration_offset.z))
    
    return true
end

-- Noise filtering using low-pass filter
local function applyNoiseFilter(new_value, filtered_value)
    return CONFIG.NOISE_FILTER_ALPHA * filtered_value + (1 - CONFIG.NOISE_FILTER_ALPHA) * new_value
end

-- Drift compensation
function SphericalCoords.updateDriftCompensation()
    local current_time = os.time()
    if current_time - state.last_drift_correction < CONFIG.DRIFT_CORRECTION_INTERVAL then
        return
    end
    
    -- Simple drift compensation based on recent readings
    if #state.raw_readings >= 10 then
        local recent_readings = {}
        for i = math.max(1, #state.raw_readings - 9), #state.raw_readings do
            table.insert(recent_readings, state.raw_readings[i])
        end
        
        -- Calculate trend and adjust drift compensation
        -- This is a simplified approach - in practice, you might use more sophisticated algorithms
        local avg_x, avg_y, avg_z = 0, 0, 0
        for _, reading in ipairs(recent_readings) do
            avg_x = avg_x + reading.x
            avg_y = avg_y + reading.y
            avg_z = avg_z + reading.z
        end
        
        avg_x = avg_x / #recent_readings
        avg_y = avg_y / #recent_readings
        avg_z = avg_z / #recent_readings
        
        -- Update drift compensation if deviation is significant
        local drift_x = math.abs(avg_x - state.calibration_offset.x)
        local drift_y = math.abs(avg_y - state.calibration_offset.y)
        local drift_z = math.abs(avg_z - state.calibration_offset.z)
        
        if drift_x > CONFIG.MAX_DRIFT_THRESHOLD or 
           drift_y > CONFIG.MAX_DRIFT_THRESHOLD or 
           drift_z > CONFIG.MAX_DRIFT_THRESHOLD then
            
            state.drift_compensation.x = state.drift_compensation.x + (avg_x - state.calibration_offset.x) * 0.1
            state.drift_compensation.y = state.drift_compensation.y + (avg_y - state.calibration_offset.y) * 0.1
            state.drift_compensation.z = state.drift_compensation.z + (avg_z - state.calibration_offset.z) * 0.1
            
            log("Drift compensation updated", "WARN")
        end
    end
    
    state.last_drift_correction = current_time
end

-- Get corrected gyro reading
function SphericalCoords.getCorrectedOrientation()
    if not state.gyro or not state.calibrated then
        log("Cannot get orientation: Gyro not calibrated", "ERROR")
        return nil
    end
    
    local reading = safeCall(function() 
        return state.gyro:GetReading() 
    end)
    
    if not reading or not reading.Orientation then
        log("Failed to get gyro reading", "ERROR")
        return nil
    end
    
    local orient = reading.Orientation
    
    -- Apply calibration offset and drift compensation
    local corrected = {
        x = orient.X - state.calibration_offset.x - state.drift_compensation.x,
        y = orient.Y - state.calibration_offset.y - state.drift_compensation.y,
        z = orient.Z - state.calibration_offset.z - state.drift_compensation.z
    }
    
    -- Apply noise filtering
    state.filtered_orientation.x = applyNoiseFilter(corrected.x, state.filtered_orientation.x)
    state.filtered_orientation.y = applyNoiseFilter(corrected.y, state.filtered_orientation.y)
    state.filtered_orientation.z = applyNoiseFilter(corrected.z, state.filtered_orientation.z)
    
    -- Store reading for drift analysis
    table.insert(state.raw_readings, corrected)
    if #state.raw_readings > 100 then
        table.remove(state.raw_readings, 1) -- Keep only recent readings
    end
    
    -- Update drift compensation
    SphericalCoords.updateDriftCompensation()
    
    return state.filtered_orientation
end

-- Core coordinate conversion functions
function SphericalCoords.sphericalToCartesian(radius, azimuth, elevation)
    --[[
    Convert spherical coordinates to Cartesian coordinates
    
    Parameters:
    - radius: Distance from origin (r)
    - azimuth: Horizontal angle in degrees (0-360°) (θ)
    - elevation: Vertical angle in degrees (-90° to +90°) (φ)
    
    Returns:
    - table with x, y, z coordinates
    ]]
    
    if not radius or not azimuth or not elevation then
        log("Invalid parameters for spherical to cartesian conversion", "ERROR")
        return nil
    end
    
    -- Convert angles to radians
    local azimuth_rad = degToRad(azimuth)
    local elevation_rad = degToRad(elevation)
    
    -- Calculate Cartesian coordinates
    -- Using standard spherical coordinate system:
    -- x = r * cos(φ) * cos(θ)
    -- y = r * cos(φ) * sin(θ)  
    -- z = r * sin(φ)
    local x = radius * math.cos(elevation_rad) * math.cos(azimuth_rad)
    local y = radius * math.cos(elevation_rad) * math.sin(azimuth_rad)
    local z = radius * math.sin(elevation_rad)
    
    local result = {x = x, y = y, z = z, radius = radius, azimuth = azimuth, elevation = elevation}
    
    if CONFIG.DEBUG_MODE then
        log(string.format("Spherical(r=%.2f, θ=%.2f°, φ=%.2f°) → Cartesian(x=%.2f, y=%.2f, z=%.2f)", 
            radius, azimuth, elevation, x, y, z))
    end
    
    return result
end

function SphericalCoords.cartesianToSpherical(x, y, z)
    --[[
    Convert Cartesian coordinates to spherical coordinates
    
    Parameters:
    - x, y, z: Cartesian coordinates
    
    Returns:
    - table with radius, azimuth, elevation
    ]]
    
    if not x or not y or not z then
        log("Invalid parameters for cartesian to spherical conversion", "ERROR")
        return nil
    end
    
    -- Calculate radius (distance from origin)
    local radius = math.sqrt(x*x + y*y + z*z)
    
    if radius == 0 then
        return {radius = 0, azimuth = 0, elevation = 0}
    end
    
    -- Calculate azimuth (horizontal angle)
    local azimuth = radToDeg(math.atan2(y, x))
    azimuth = clampAngle(azimuth)
    
    -- Calculate elevation (vertical angle)
    local elevation = radToDeg(math.asin(z / radius))
    
    local result = {radius = radius, azimuth = azimuth, elevation = elevation, x = x, y = y, z = z}
    
    if CONFIG.DEBUG_MODE then
        log(string.format("Cartesian(x=%.2f, y=%.2f, z=%.2f) → Spherical(r=%.2f, θ=%.2f°, φ=%.2f°)", 
            x, y, z, radius, azimuth, elevation))
    end
    
    return result
end

-- Gyro-based coordinate functions
function SphericalCoords.getSphericalFromGyro(radius)
    --[[
    Get spherical coordinates using current gyro orientation
    
    Parameters:
    - radius: Distance from origin (if known)
    
    Returns:
    - table with spherical coordinates based on gyro orientation
    ]]
    
    local orientation = SphericalCoords.getCorrectedOrientation()
    if not orientation then
        return nil
    end
    
    -- Convert gyro orientation to spherical angles
    -- This assumes gyro provides Euler angles or can be converted to them
    local azimuth = clampAngle(radToDeg(orientation.y))  -- Yaw
    local elevation = math.max(-90, math.min(90, radToDeg(orientation.x)))  -- Pitch (clamped)
    
    radius = radius or 1.0  -- Default radius if not provided
    
    return SphericalCoords.sphericalToCartesian(radius, azimuth, elevation)
end

-- Navigation and tracking functions
function SphericalCoords.getRelativePosition(target_position, reference_position)
    --[[
    Calculate relative spherical coordinates between two positions
    
    Parameters:
    - target_position: Vector3 or table with x,y,z
    - reference_position: Vector3 or table with x,y,z (optional, uses current if nil)
    
    Returns:
    - spherical coordinates of target relative to reference
    ]]
    
    reference_position = reference_position or {x = 0, y = 0, z = 0}
    
    if not target_position then
        log("Target position required for relative position calculation", "ERROR")
        return nil
    end
    
    -- Calculate relative vector
    local rel_x = target_position.x - reference_position.x
    local rel_y = target_position.y - reference_position.y  
    local rel_z = target_position.z - reference_position.z
    
    return SphericalCoords.cartesianToSpherical(rel_x, rel_y, rel_z)
end

-- Module initialization
function SphericalCoords.init(gyro_component)
    --[[
    Initialize the spherical coordinates module
    
    Parameters:
    - gyro_component: Gyro part from WOS (required)
    
    Returns:
    - boolean indicating success
    ]]
    
    if not gyro_component then
        log("Gyro component is required for initialization", "ERROR")
        return false
    end
    
    state.gyro = gyro_component
    log("SphericalCoords module initialized")
    
    -- Perform initial calibration
    task.spawn(function()
        task.wait(1) -- Allow gyro to stabilize
        if SphericalCoords.calibrateGyro() then
            state.initialized = true
            log("Module ready for use")
        else
            log("Module initialization failed during calibration", "ERROR")
        end
    end)
    
    return true
end

-- Configuration functions
function SphericalCoords.setDebugMode(enabled)
    CONFIG.DEBUG_MODE = enabled
    log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

function SphericalCoords.setNoiseFilterAlpha(alpha)
    if alpha >= 0 and alpha <= 1 then
        CONFIG.NOISE_FILTER_ALPHA = alpha
        log("Noise filter alpha set to " .. alpha)
    else
        log("Invalid noise filter alpha (must be 0-1)", "ERROR")
    end
end

-- Status and diagnostic functions
function SphericalCoords.getStatus()
    return {
        initialized = state.initialized,
        calibrated = state.calibrated,
        gyro_connected = state.gyro ~= nil,
        calibration_offset = state.calibration_offset,
        drift_compensation = state.drift_compensation,
        filtered_orientation = state.filtered_orientation,
        readings_count = #state.raw_readings
    }
end

function SphericalCoords.printStatus()
    local status = SphericalCoords.getStatus()
    print("=== SphericalCoords Module Status ===")
    print("Initialized: " .. tostring(status.initialized))
    print("Calibrated: " .. tostring(status.calibrated))
    print("Gyro Connected: " .. tostring(status.gyro_connected))
    if status.calibrated then
        print(string.format("Calibration Offset: X=%.3f, Y=%.3f, Z=%.3f", 
            status.calibration_offset.x, status.calibration_offset.y, status.calibration_offset.z))
        print(string.format("Drift Compensation: X=%.3f, Y=%.3f, Z=%.3f", 
            status.drift_compensation.x, status.drift_compensation.y, status.drift_compensation.z))
    end
    print("Readings Stored: " .. status.readings_count)
    print("=====================================")
end

return SphericalCoords