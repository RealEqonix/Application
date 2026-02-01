--NOTE: THIS CONTAINS AI GENERATED PRINTS, TO HELP DEBUG. NOTHING PHYSICAL, NOR COMMENTS IS AI-GENERATED!
--[[
	Made by: Discord("theodor.la"), ROBLOX("Blockig599")
]]

local DataManager = require(ServerScriptService.Data.DataManager)
local ModuleLoader = require(ServerScriptService.ModuleLoader)
local Modules = ModuleLoader.Load(script.Modules)

local RoundManager = Modules.RoundManager
local Combat = Modules.Combat
local PlayerState = Modules.PlayerState
local Spawning = Modules.Spawning
local Animations = Modules.Animations
local Rewards = Modules.Rewards

-- Module links
Combat.HitboxTemplate = ReplicatedStorage.Hitbox
Combat.DataManager = DataManager
Rewards.DataManager = DataManager

-- Game variables
local gameStatus = "Waiting"
local MIN_PLAYERS = 1
local REQUIRED_PLAYERS_TO_WIN =0  -- adjustable for testing
local spawnPart = workspace.Arena
local playlist = workspace.music

-- Events
local PlayerAfterimageEvent = ReplicatedStorage.Events:WaitForChild("PlayerAfterimage")

-- Helper functions
local function softRestart()
	for _, player in ipairs(Players:GetPlayers()) do
		player:Kick("Restarting the game...")
	end
end

-- Get a player's Shout Frame
local function getShout(plr)
	if not plr then return nil end

	local gui = plr:WaitForChild("PlayerGui", 1)
	
	return gui.Base.Shout
end

-- Update a player's shout text
local function updateShout(plr, msg)
	local shout = getShout(plr)
	if not shout then
		warn("[updateShout] Could not find shout for player:", plr.Name)
		return
	end

	local textLabel = shout:FindFirstChild("TextLabel")
	if not textLabel or not textLabel:IsA("TextLabel") then
		warn("[updateShout] Could not find TextLabel in Shout for player:", plr.Name)
		return
	end

	textLabel.Text = msg
end

local function shoutServer(msg)
	for _, plr in ipairs(Players:GetPlayers()) do
		updateShout(plr, msg)
	end
end

local function getRandomPlayersShout()
	local validPlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local shout = getShout(plr)
		if shout and shout:FindFirstChild("TextLabel") then
			table.insert(validPlayers, plr)
		end
	end
	if #validPlayers == 0 then return nil end
	local chosen = validPlayers[math.random(#validPlayers)]
	return getShout(chosen).TextLabel.Text
end

local function failSafe()
	local shoutText = getRandomPlayersShout()
	if not shoutText then
		warn("[FAILSAFE] No valid shouts available")
		softRestart()
		return
	end
	if shoutText ~= "Waiting" then return end

	task.wait(10)
	shoutText = getRandomPlayersShout()
	if not shoutText then
		warn("[FAILSAFE] No valid shouts available")
		softRestart()
		return
	end
	if shoutText == "Waiting" then
		softRestart()
	end
end

-- Continuously check for fail-safe
task.spawn(function()
	task.wait(3)
	
	while true do
		task.wait(1)
		--failSafe()
	end
end)

-- Check if enough players are present
local function enoughPlayers(required)
	required = required or MIN_PLAYERS
	return #Players:GetPlayers() >= required
end

-- Prepare a character for the round
local function prepCharacter(char)
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	Spawning.SpawnCharacter(char, spawnPart)
	PlayerState.SetInGame(char, true)
	PlayerState.SetPowersVisible(char, true)
end

-- Timer function
local function startTimer(timerText: string, timerVal: number)
	for timer = timerVal, 0, -1 do
		if not enoughPlayers() then
			for _, plr in ipairs(Players:GetPlayers()) do
				updateShout(plr, "Waiting for players (" .. #Players:GetPlayers() .. "/" .. MIN_PLAYERS .. ")")
			end
			gameStatus = "Waiting"
			return false
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			updateShout(plr, (`{timerText}{timer}s`))
			if timer < 4 then
				ReplicatedStorage.TimeSFX:Play()
			end
		end

		if timer > 0 then task.wait(1) end
	end
	return true
end

-- Random spawn position
local function getRandomSpawnCFrame(part)
	local size = part.Size
	local center = part.Position

	local function biasedOffset(range)
		local r = math.random()
		return (r * r - 0.5) * range
	end

	local offsetX = biasedOffset(size.X)
	local offsetZ = biasedOffset(size.Z)
	local y = center.Y + size.Y/2 + 4
	local yaw = math.rad(math.random(0, 360))

	return CFrame.new(center.X + offsetX, y, center.Z + offsetZ) * CFrame.Angles(0, yaw, 0)
end

-- Toggle visibility for all players
local function toggleVisibility(bool)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character or plr.CharacterAdded:Wait()
		if bool == false then
			ReplicatedStorage.Events.PlayerInvis:FireClient(plr)
			local animator = char.Humanoid:FindFirstChild("Animator")
			animator:LoadAnimation(script.Hold):Play()
		else
			ReplicatedStorage.Events.PlayerVisible:FireClient(plr)
			local animator = char.Humanoid:FindFirstChild("Animator")
			animator:LoadAnimation(script.Hold):Stop()
		end
	end
end

-- Start a random song
local function startSong()
	for _, sound in ipairs(playlist:GetChildren()) do sound:Stop() end
	local newSong = playlist:GetChildren()[math.random(1, #playlist:GetChildren())]
	newSong:Play()
end

local function stopSong()
	for _, sound in ipairs(playlist:GetChildren()) do sound:Stop() end
end

startSong()

-- Main round loop
local function startLoop()	
	print("[ROUND] startLoop ENTERED")
	
	workspace.Arena.Size = Vector3.new(50, workspace.Arena.Size.Y, 50)

	-- Pre-round countdown
	local countdownTime = 20
	print("[ROUND] Pre-round countdown:", countdownTime)

	for t = countdownTime, 1, -1 do
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then
				print("[ROUND] Waiting for character for player:", plr.Name)
				continue
			end
			updateShout(plr, "Round starts in "..t.."s")
		end
		
		if t < 4 then
			ReplicatedStorage.TimeSFX:Play()
		end
		task.wait(1)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		updateShout(plr, "GO!")
	end
	
	ReplicatedStorage.Starting:Play()

	task.wait(1)
	print("[ROUND] Pre-round countdown finished")

	-- Prep all characters
	for _, plr in ipairs(Players:GetPlayers()) do
		prepCharacter(plr.Character)
	end

	print("[ROUND] Entering main round loop")
	
	stopSong()
	
	local currentMap = workspace.Map:GetChildren()[1]
	
	if currentMap then
		currentMap.Music:Play()
	end

	-- Main loop
	while #workspace.PlayersInGame:GetChildren() > 0 do
		print("[ROUND] Loop tick | Players:", #workspace.PlayersInGame:GetChildren())

		-- Check which players are inside bounds
		local playersInBounds = {}
		local parts = workspace:GetPartBoundsInBox(workspace.CheckBox.CFrame, workspace.CheckBox.Size)
		for _, part in ipairs(parts) do
			local char = part:FindFirstAncestorOfClass("Model")
			if char and CollectionService:HasTag(char, "InGame") then
				if not table.find(playersInBounds, char) then
					table.insert(playersInBounds, char)
				end
			end
		end

		print("[ROUND] Players in bounds:", #playersInBounds)

		-- WIN CHECK
		if #playersInBounds <= REQUIRED_PLAYERS_TO_WIN then
			if #playersInBounds > 0 then
				print("[ROUND] 🏆 Winner found:", playersInBounds[1].Name)
				
				local char = playersInBounds[1]
				char.Humanoid.WalkSpeed = 22
				char.Humanoid.AutoRotate = true
				
				DataManager.EditStat(playersInBounds[1].Name, "Wins", 1, "add")
				DataManager.EditStat(playersInBounds[1].Name, "Coins", 25, "add")
				
				ReplicatedStorage.Win:Play()
				
				for _, plr in ipairs(Players:GetPlayers()) do
					updateShout(plr, playersInBounds[1].Name.. " Won!")
				end
			else
				print("[ROUND] ❌ No players left alive")
				
				ReplicatedStorage.AllLost:Play()
				
				for _, plr in ipairs(Players:GetPlayers()) do
					updateShout(plr, "Everyone died!")
				end
			end
			
			
			return true
		end

		-- HOLD PHASE
		print("[ROUND] HOLD phase")
		for _, char in ipairs(workspace.PlayersInGame:GetChildren()) do
			PlayerState.SetMovement(char, true)
			Animations.PlayHold(char, script.Hold)
		end
		toggleVisibility(false)

		if startTimer("Revealing players in ", 10) ~= true then
			print("[ROUND] ❌ Timer aborted")
			return false
		end

		-- REVEAL PHASE
		print("[ROUND] REVEAL phase")
		toggleVisibility(true)
		for _, char in ipairs(workspace.PlayersInGame:GetChildren()) do
			PlayerState.SetMovement(char, false)
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			updateShout(plr, "Revealed Players!")
		end
		task.wait(1)

		-- ATTACK PHASE
		print("[ROUND] ATTACK phase")
		for _, char in ipairs(workspace.PlayersInGame:GetChildren()) do
			Animations.PlayUse(char, script.Hold, script.Use)
		end
		task.wait(0.5)

		-- COMBAT
		print("[ROUND] Resolving combat")
		local deadChars = Combat.Resolve(workspace.PlayersInGame:GetChildren())
		print("[ROUND] Dead this round:", #deadChars)

		for _, char in ipairs(deadChars) do
			
			char.Humanoid.Health = 0
			PlayerState.SetInGame(char, false)
			PlayerState.SetPowersVisible(char, false)
		end

		task.wait(3)
		TweenService:Create(workspace.Arena, TweenInfo.new(1), {Size = Vector3.new(workspace.Arena.Size.X - 8, workspace.Arena.Size.Y, workspace.Arena.Size.Z -  8)}):Play()
	end
	
	local playersInBounds = {}
	local parts = workspace:GetPartBoundsInBox(workspace.CheckBox.CFrame, workspace.CheckBox.Size)
	for _, part in ipairs(parts) do
		local char = part:FindFirstAncestorOfClass("Model")
		if char and CollectionService:HasTag(char, "InGame") then
			if not table.find(playersInBounds, char) then
				table.insert(playersInBounds, char)
			end
		end
	end
	
	if #playersInBounds <= REQUIRED_PLAYERS_TO_WIN then
		if #playersInBounds > 0 then
			print("[ROUND] 🏆 Winner found:", playersInBounds[1].Name)

			DataManager.EditStat(playersInBounds[1].Name, "Wins", 1, "add")
			DataManager.EditStat(playersInBounds[1].Name, "Coins", 25, "add")

			ReplicatedStorage.Win:Play()

			for _, plr in ipairs(Players:GetPlayers()) do
				updateShout(plr, playersInBounds[1].Name.. " Won!")
			end
		else
			print("[ROUND] ❌ No players left alive")

			ReplicatedStorage.AllLost:Play()

			for _, plr in ipairs(Players:GetPlayers()) do
				updateShout(plr, "Everyone died!")
			end
		end


		return true
	end
	
	print("[ROUND] Loop exited naturally")
	return false
end

-- Player updates

RoundManager.MIN_PLAYERS = MIN_PLAYERS
RoundManager.StartLoop = startLoop

local function onPlayerUpdate()
	RoundManager:TryStart()
end

Players.PlayerAdded:Connect(function()
	task.wait(1)
	onPlayerUpdate()
end)
Players.PlayerRemoving:Connect(onPlayerUpdate)
