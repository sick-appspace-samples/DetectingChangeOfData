
--Start of Global Scope---------------------------------------------------------

local DELAY = 1000 -- ms between each type for demonstration purpose

--Frequency of TIM5xx sensor
local FREQUENCY = 15 --Hz

local BLUE = {59, 156, 208}
local ORANGE = {242, 148, 0}

local angles = {}
for i = -45, 225, 1 do
  angles[#angles + 1] = i / 180 * math.pi
end

--------------------------------------------------------------------------
-- Helper functions ------------------------------------------------------
--------------------------------------------------------------------------

local function graphDeco(color, headline, overlay)
  local deco = View.GraphDecoration.create()
  deco:setPolarPlot(true)
  deco:setGraphColor(color[1], color[2], color[3], color[4] or 255)
  deco:setGraphType('DOT')
  deco:setDynamicSizing(true)
  deco:setYBounds(0, 4000)
  deco:setAxisVisible(false)
  deco:setLabelsVisible(false)
  deco:setGridVisible(false)
  deco:setTicksVisible(false)
  if overlay then
    deco:setBackgroundVisible(false)
  else
    deco:setTitle(headline or '')
  end
  return deco
end

local function replaceCoords(profile, newCoords)
  local values, _, flags = Profile.toVector(profile)
  return Profile.createFromVector(values, newCoords, flags)
end

--------------------------------------------------------------------------
-- Main code -------------------------------------------------------------
--------------------------------------------------------------------------
local function main()
  -- Load teaching as well as test data
  local teachScans = Object.load('resources/teachData.json')
  local sampleScans = Object.load('resources/sampleData.json')

  -- Calculate reference profile
  local teachProfiles = {}
  for _, data in pairs(teachScans) do
    teachProfiles[#teachProfiles + 1] = Scan.toProfile(data, 'DISTANCE')
  end
  -- Aggregate data to gain reference profile
  local referenceProfile = replaceCoords(Profile.aggregate(teachProfiles, 'MEDIAN'), angles)

  local v = View.create()

  -- View reference profile
  v:clear()
  v:addProfile(referenceProfile, graphDeco(BLUE, 'Reference'))
  v:present()
  Script.sleep(DELAY) -- for demonstration purpose only

  local frameTimeout = math.floor(1000 / FREQUENCY)

  -- Iterate over sample data
  for _, data in pairs(sampleScans) do
    -- Create profile of current frame
    local curFrameProfile = replaceCoords(Scan.toProfile(data, "DISTANCE"), angles)

    -- Calculate absolute difference between current frame and reference
    local diff = Profile.subtract(referenceProfile, curFrameProfile)
    diff = Profile.abs(diff)
    -- Use difference above 50mm as valid flags for a new profile of changed points
    diff = Profile.binarize(diff, 50)
    local validVec = Profile.toVector(diff) -- Use values of diff profile as valid vector
    local values = Profile.toVector(curFrameProfile)
    local changeProfile = Profile.createFromVector(values, angles, validVec)

    -- Visualize frame with difference
    v:clear()
    local id = v:addProfile(curFrameProfile, graphDeco(BLUE, 'Scan'))
    v:addProfile(changeProfile, graphDeco(ORANGE, '', true), nil, id)
    v:present()

    Script.sleep(frameTimeout)
  end
  print("App finished") 
end
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope--------------------------------------------------