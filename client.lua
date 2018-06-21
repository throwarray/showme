local function NEAR (enumerator, _table)
    local output = _table or {}
    for entity in enumerator() do
        output[tostring(entity)] = entity
    end
    return output
end

function AllWorldObjects (...) return NEAR(EnumerateObjects, ...) end
function AllWorldPeds (...) return NEAR(EnumeratePeds, ...) end
function AllWorldVehicles (...)  return NEAR(EnumerateVehicles, ...) end
function AllWorldPickups (...) return NEAR(EnumeratePickups, ...) end

local ALL_WORLD_ENTITIES = {}
Citizen.CreateThread(function ()
    while true do
        AllWorldObjects(ALL_WORLD_ENTITIES)
        AllWorldVehicles(ALL_WORLD_ENTITIES)
        AllWorldPeds(ALL_WORLD_ENTITIES)
        AllWorldPickups(ALL_WORLD_ENTITIES)
        Citizen.Wait(300)
    end
end)

function GetDistanceBetween (a, b)
    return GetDistanceBetweenCoords(a.x, a.y, a.z, b.x, b.y, b.z)
end

function LineBetween (a, b, rd, gr, bl, al, bool)
    if a and b and bool then
        DrawLine(b.x, b.y, b.z, a.x, a.y, a.z, rd, gr, bl, al);
    end
end

local function DrawEntityBox(entity, r,g,b,a)
    local pos = nil
    local min = nil
    local max = nil
    if entity.entity ~= nil then
        pos = entity.coords
        min = entity.min
        max = entity.max
        entity.min, entity.max = GetModelDimensions(entity.model, entity.min or {}, entity.max or {})

        DrawLine(
            pos.x,
            pos.y,
            pos.z + max.z,
		    pos.x,
            pos.y,
            pos.z + min.z,
            0, 0, 255, 80
        );
    end
end


local function EntityStats (entity, obj)
    local stats = obj or {}
    stats.entity = entity
    stats.coords = GetEntityCoords(entity)
    stats.heading = GetEntityHeading(entity)
    stats.entityType = GetEntityType(entity)
    stats.distance = GetDistanceBetween(GetEntityCoords(GetPlayerPed(-1)), stats.coords)
    stats.model = GetEntityModel(entity)
    stats.health = GetEntityHealth(entity)
    stats.maxHealth = GetEntityMaxHealth(entity)
	stats.interior = GetInteriorAtCoords(table.unpack(stats.coords))
	stats.room = 0
	if stats.interior ~= 0 then
		stats.room = GetKeyForEntityInRoom(entity) or 0
	end -- GET_ROOM_KEY_FROM_ENTITY seems to throw errors for w.e reason
	stats.min, stats.max = GetModelDimensions(stats.model, stats.min or {}, stats.max or {})
	-- stats.staticEntity = IsEntityStatic(entity)
	-- stats.missionEntity = IsEntityAMissionEntity(entity)
    return stats
end


function DisplayTextThisFrame (text, posX, posY, scale, props)
	local x = nil
	local y = nil
	local bg = nil
	local lineHeight = nil
	local lineCount = 1
	local halfWidth = 0
	local font = 0
	local screenW, screenH = GetActiveScreenResolution()
	local ratio = GetAspectRatio(false)
	local align = 1

	if type(props) == 'table' then
		local shadow = props.shadow or nil

		font = props.font or font

		bg = props.background or props.backgroundColor

		if scale == nil then scale = props.scale end

		if props.outline == true then SetTextOutline() end

		if props.color ~= nil then
			SetTextColour(
			props.color[1], -- r
			props.color[2], -- g
			props.color[3], -- b
			props.color[4]  -- a
		) end

		align = props.align or props.textAlign

		if type(align) == 'string' then
			if align == 'center' then align = 0
			elseif align == 'right' then align = 2
			else align = 1 end
		end

		if shadow == true or shadow == 1 then SetTextDropShadow()
		elseif shadow ~= nil then
			SetTextDropshadow(
			shadow[1], -- d
			shadow[2], -- r
			shadow[3], -- g
			shadow[4], -- b
			shadow[5]  -- a
		) end
	end

	scale = scale or 0.0
	lineHeight = (GetTextScaleHeight(scale, font) or 0.0) * ratio
	screenW = screenW * ratio
	screenH = screenH * ratio
	x = (posX * ratio) / screenW
	y = (posY * ratio) / screenH

	-- DRAW BACKGROUND
	if bg then
		BeginTextCommandWidth("jamyfafi")
		SetTextFont(font)
		SetTextScale(1.0, scale)

		for i = 0, #text, 99 do AddTextComponentString(string.sub(text, i, i + 98)) end
		halfWidth = (EndTextCommandGetWidth(true) or 0.0) * 0.5

		-- TODO
		-- BeginTextCommandLineCount("jamyfafi")
		-- SetTextFont(font)
		-- SetTextScale(1.0, scale)
		-- for i = 0, #text, 99 do AddTextComponentString(string.sub(text, i, i + 98)) end
		-- lineCount = EndTextCommandGetLineCount(x, halfWidth * 2) -- wrap x, end?

		-- IDEA
		-- local wordWrap = nil
		-- if wordWrap then
		--     local size = (posX + wordWrap) / width
		--     SetTextWrap(x or 0.0, size)
		-- end

		-- TODO RIGHT -- SetTextWrap(0, x)
		-- if align == 2 then SetTextWrap(x - halfWidth, x + halfWidth) end
		-- CENTER

		if align == 0 then
			SetTextJustification(align)
			DrawRect(x, y + (lineHeight * 0.5), halfWidth * 2, lineHeight, bg[1], bg[2], bg[3], bg[4])
		-- LEFT
		else
			DrawRect(x + halfWidth, y + (lineHeight * 0.5), halfWidth * 2, lineHeight, bg[1], bg[2], bg[3], bg[4])
		end
	end

	-- DRAW TEXT
	SetTextEntry("jamyfafi")
	SetTextFont(font)
	SetTextScale(1.0, scale)
	for i = 0, #text, 99 do AddTextComponentString(string.sub(text, i, i + 98)) end
	DrawText(x, y)
end

local STYLE_NEARBY_ENTITY_STATS = {
	background = { 0, 0, 0, 80 };
	shadow = { 1, 0, 0, 0, 255 };
}
local function DisplayNearbyEntityInfo (e, text)
    SetDrawOrigin(e.coords.x, e.coords.y, e.coords.z + e.max.z + 0.25)
        DisplayTextThisFrame(text, 0.0, 0.0, 0.25, STYLE_NEARBY_ENTITY_STATS)
    ClearDrawOrigin()
end

local STYLE_PLAYER_ENTITY_STATS = {
	background = { 0, 0, 0, 255 };
	shadow = { 1, 0, 0, 0, 255 };
}
local function DisplayPlayerEntityStats (player, nearest)
    local near = player.entity
	local screenW, screenH = GetActiveScreenResolution()
    if nearest.entity ~= nil then near = nearest.entity end
    DisplayTextThisFrame(string.format("~r~E: ~s~%i ~r~X: ~s~%.2f ~r~Y: ~s~%.2f ~r~Z: ~s~%.2f ~r~R: ~s~%.2f ~r~N: ~s~%i ~r~I: ~s~%i ~s~%i",
        player.entity,
        player.coords.x,
        player.coords.y,
        player.coords.z,
        player.heading,
        near,
		player.interior,
		player.room
    ), 22, screenH - 18, 0.23, STYLE_PLAYER_ENTITY_STATS)
end


local STYLE_CHOSEN_ENTITY_STATS = {
	background = { 0, 0, 0, 200 };
	shadow = { 1, 0, 0, 0, 255 };
	textAlign = 0;
}
local function DisplayChosenEntityStats (e)
	local screenW, screenH = GetActiveScreenResolution()
    DisplayTextThisFrame(string.format("~r~E: ~s~%i ~r~M: ~s~%i ~r~T: ~s~%i ~r~H: ~s~%.2f/~s~%.2f ~r~D: ~s~%.2f ~r~X: ~s~%.2f ~r~Y: ~s~%.2f ~r~Z: ~s~%.2f ~r~R: ~s~%.2f ~r~I: ~s~%i ~s~%i",
        e.entity or 0,
        e.model,
		e.entityType,
		e.health,
		e.maxHealth,
        e.distance,
        e.coords.x, e.coords.y, e.coords.z,
        e.heading,
		e.interior,
		e.room
	), screenW / 2, 0.0, 0.33, STYLE_CHOSEN_ENTITY_STATS)
end

local function SetClipboardChosenEntityStats (e)
    exports.clipboard:SetClipboard({
        entity = e.entity,
        model = e.model,
        entityType = e.entityType,
        health = e.health,
        maxHealth = e.maxHealth,
        distance = e.distance,
        x = e.coords.x,
        y = e.coords.y,
        z = e.coords.z,
        heading = e.heading,
        interior = e.interior,
        room = e.room
    }, function (err)
        --print('SET CLIPBOARD SUCCESS', not err)
    end)  
end


Citizen.CreateThread(function ()
    local player = {}
    local nearest = {}
    local targeted = {}
    local selected = {}
    local current = {}
    local draw = {}

    -- TODO
    local OPTS = {}
    OPTS.lineToTarget = true
    OPTS.lineToTargetRadius = math.huge
    OPTS.lineToNearest = true
    OPTS.lineToNearestRadius = 10.0
    OPTS.markerAboveNearest = true

    OPTS.labelNearbyRadius = 5.0

    selected.from_aim = true

    RegisterCommand('showme', function (source, args, rawCommand)
        local entity = tonumber(args[1])
        if not entity then
            selected.from_aim = true
            selected.entity = nil
			--RefreshInterior(player.interior or 0) -- (changes entity handles)
        else
            selected.from_aim = false
			EntityStats(tonumber(entity), selected)
			LoadInterior(selected.interior)

			if args[2] == 'true' or args[2] == true then
			    SetClipboardChosenEntityStats(selected)
			end
        end
    end, false)

    while true do
        -- FRAME RESET --------------------------------------------------------
        Citizen.Wait(0)
        EntityStats(GetPlayerPed(-1), player)
        EntityStats(selected.entity, selected)

        targeted.entity = 0 -- expects int
        targeted.targeted = false
        targeted.targeted, targeted.entity = GetEntityPlayerIsFreeAimingAt(GetPlayerIndex(), targeted.entity)
		if not targeted.targeted then
			targeted.targeted, targeted.entity = GetPlayerTargetEntity(GetPlayerIndex(), targeted.entity)
		end


        EntityStats(targeted.entity, targeted)

        nearest.distance = math.huge
        nearest.entity = nil
        ------------------------------------------------------------------------

        for k,v in pairs(ALL_WORLD_ENTITIES) do
            if not DoesEntityExist(v) then ALL_WORLD_ENTITIES[k] = nil -- Clean destroyed entities
            else
                EntityStats(v, current)
                if IsEntityOnScreen(v) and current.distance <= OPTS.labelNearbyRadius then
                    DisplayNearbyEntityInfo(current, k)
                end
                -- NEAREST ENTITY
                if current.entity ~= player.entity and current.distance < nearest.distance then
                    EntityStats(v, nearest)
                end
            end
        end

        -- PLAYER INFO
        DisplayPlayerEntityStats(player, nearest) -- Player stats below map

        -- -- PLAYER AIM TARGET
        if targeted.targeted then
            LineBetween(
                player.coords, targeted.coords,
                255, 0, 0, 100,
                OPTS.lineToTarget and targeted.distance < OPTS.lineToTargetRadius
            )
            DrawMarker(
                31, --wolf
                targeted.coords.x,
                targeted.coords.y,
                targeted.coords.z + targeted.max.z + 0.05,
                0.0, 0.0, 0.0, 0, 0.0, 0.0,
                0.2, 0.2, 0.2,
                255, 0, 0, 100,
                false, true, 2, false, false, false, false
            )
        else targeted.entity = nil end

        -- NEAREST ENTITY
        if nearest.entity ~= nil and nearest.entity ~= targeted.entity then
            if OPTS.markerAboveNearest then
                DrawMarker(
                    31, --wolf
                    nearest.coords.x,
                    nearest.coords.y,
                    nearest.coords.z + nearest.max.z + 0.05,
                    0.0, 0.0, 0.0, 0, 0.0, 0.0,
                    0.2, 0.2, 0.2,
                    0, 255, 0, 100,
                    false, true, 2, false, false, false, false
                )
            end
            DrawEntityBox(nearest, 255,0,0,255)
            LineBetween(
                player.coords, nearest.coords,
                0, 255, 0, 100,
                OPTS.lineToNearest and nearest.distance < OPTS.lineToNearestRadius
            )
        end

        -- CHOSEN | TARGET | NEAREST EXTENDED STATS
        if selected.entity then DisplayChosenEntityStats(selected)
        elseif targeted.entity then DisplayChosenEntityStats(targeted)
        elseif nearest.entity then DisplayChosenEntityStats(nearest) end
    end
end)
