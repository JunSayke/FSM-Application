-- Define the FSM class
local FSM = {}
FSM.__index = FSM

-- Transition table for states
FSM.STATE_TRANSITION_TABLE = {
	idle = {
		player_in_range = "attack",
		player_not_in_range = "idle",
		health_is_low = "escape",
		zero_hp = "die",
	},
	attack = {
		player_in_range = "attack",
		player_not_in_range = "idle",
		health_is_low = "escape",
		zero_hp = "die",
	},
	escape = {
		player_in_range = "attack",
		player_not_in_range = "idle",
		health_is_low = "escape",
		zero_hp = "die",
	},
	die = {
		player_in_range = "die",
		player_not_in_range = "die",
		health_is_low = "die",
		zero_hp = "die",
	},
}

-- Convert string into title case
local function toProper(string)
	local split = string:split(' ')
	for i,v in ipairs(split) do
		split[i] = v:sub(1, 1):upper()..v:sub(2):lower()
	end
	return table.concat(split, ' ')
end

-- Constructor for FSM
function FSM.new(npc)
	local self = setmetatable({}, FSM)
	self.npc = npc
	self.defaultWalkSpeed = 10
	self.human = npc.Humanoid
	self.human.WalkSpeed = self.defaultWalkSpeed
	self.human.MaxHealth = 500
	self.human.Health = 500
	self.attackRange = 30
	self.escapeDistance = 50
	self.currentState = 'idle'  -- Start with the idle state
	self.target = nil
	self.respawnTime = 5 -- in seconds
	self.attackCooldown = 2 -- Time in seconds between attacks
	self.lastAttackTime = 0 -- Timestamp of last attack
	
	self.originalNpcClone = npc:Clone()  -- Clone the NPC for respawning later
	
	self.weapon = self.npc:FindFirstChild("Sword")
	self:initializeOverheadGui()
	self:createAttackRangeVisualization()
	return self
end

-- Method to handle state transitions
function FSM:transitionState(condition)
	local stateTransition = FSM.STATE_TRANSITION_TABLE[self.currentState]
	if stateTransition and stateTransition[condition] then
		local newState = stateTransition[condition]
		self:setState(newState)
	end
end

-- Method to set the current state
function FSM:setState(state)
	if state ~= self.currentState then
		self.currentState = state
		print("Transitioned to state:", self.currentState)

		-- Adjust speed when health is low
		if self.currentState == "escape" then
			self.human.WalkSpeed = self.human.WalkSpeed * 2 -- Slow down to 50% of normal speed when health is low
		else
			self.human.WalkSpeed = self.defaultWalkSpeed -- Reset to normal speed
		end

		-- Update the TextLabel to show the current state
		if self.stateTextLabel then
			self.stateTextLabel.Text = toProper(self.currentState)
		end
	end
end
-- Method to find the nearest target
function FSM:findTarget()
	local nearestTarget
	local maxDistance = self.attackRange
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if player.Character then
			local target = player.Character
			if target:WaitForChild("Humanoid").Health > 0 then
				local distance = (self.npc.HumanoidRootPart.Position - target:WaitForChild("HumanoidRootPart").Position).Magnitude
				if distance < maxDistance then
					nearestTarget = target
					maxDistance = distance
				end
			end
		end
	end
	self.target = nearestTarget
	return nearestTarget
end

-- Method to handle the idle state
function FSM:idleState()
	print("NPC is in idle state.")
	if self.attackRangeVisualization then
		self.attackRangeVisualization.Size = Vector3.new(self.attackRange * 2, self.attackRange * 2, self.attackRange * 2)
		self.attackRangeVisualization.Color = Color3.fromRGB(144, 238, 144)
	end
	
	local target = self:findTarget()
	if target then
		self:transitionState("player_in_range")
	else
		self.human:MoveTo(self.npc.PrimaryPart.Position)
		-- Heal gradually over time
		if self.human.Health < self.human.MaxHealth then
			self.human.Health = math.min(self.human.Health + 1, self.human.MaxHealth) -- Heal by 1 HP each update until full health
		end
	end
end

-- Method to handle the attack state
function FSM:attackState()
	print("NPC is in attack state.")
	if self.target and self.target.Humanoid.Health > 0 then
		self.human:MoveTo(self.target.HumanoidRootPart.Position)
		
		if self.attackRangeVisualization then
			self.attackRangeVisualization.Size = Vector3.new(self.attackRange * 2, self.attackRange * 2, self.attackRange * 2)
			self.attackRangeVisualization.Color = Color3.fromRGB(255, 127, 127)
		end

		if (self.npc.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).Magnitude < 5 then
			if tick() - self.lastAttackTime >= self.attackCooldown then
				-- Simulate the tool's attack
				if self.weapon then
					self.weapon.CanDamage.Value = true
					self.weapon:Activate()  -- This simulates a left-click attack
				end

				self.lastAttackTime = tick() -- Update the timestamp of the last attack
			end
		end

		if (self.npc.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).Magnitude > self.attackRange then
			self:transitionState("player_not_in_range")
		elseif self.human.Health < self.human.maxHealth * 0.3 then
			self:transitionState("health_is_low")
		end
	else
		self:transitionState("player_not_in_range")
	end
end

-- Method to handle the escape state
function FSM:escapeState()
	print("NPC is in escape state.")
	local safeDistance = 50
	local fleeDirection = (self.npc.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).Unit
	local fleePosition = self.npc.HumanoidRootPart.Position + fleeDirection * safeDistance
	
	if self.attackRangeVisualization then
		self.attackRangeVisualization.Size = Vector3.new(self.escapeDistance * 2, self.escapeDistance * 2, self.escapeDistance * 2)
		self.attackRangeVisualization.Color = Color3.fromRGB(255, 213, 128)
	end
	
	self.human:MoveTo(fleePosition)

	if (self.npc.HumanoidRootPart.Position - self.target.HumanoidRootPart.Position).Magnitude > safeDistance then
		self:transitionState("player_not_in_range")
	end
end

-- Method to handle the dying state with complete NPC reset and respawn
function FSM:dieState()
	print("NPC is in die state.")

	-- Save the current position for respawn
	local respawnPosition = self.respawnPosition

	task.wait(2)
	
	-- Destroy the current NPC model
	if self.npc then
		self.npc:Destroy()
		print("NPC has been destroyed.")
	end

	-- Wait for 5 seconds before respawning
	task.wait(self.respawnTime)
	self:respawn()
end

-- Method to create a new NPC using the stored clone
function FSM:respawn()
	local npc = self.originalNpcClone:Clone()
	npc.Parent = workspace -- Add the new NPC to the game world
end

-- Method to create the overhead gui for showing current state
function FSM:initializeOverheadGui()
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 50) -- Adjust the size as needed
	billboardGui.StudsOffset = Vector3.new(0, 10, 0) -- Offset above the NPC's head
	billboardGui.Adornee = self.npc:FindFirstChild("HumanoidRootPart")
	billboardGui.Parent = self.npc

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = toProper(self.currentState)
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
	textLabel.TextStrokeTransparency = 0 -- Outline to make the text more readable
	textLabel.TextScaled = true
	textLabel.Parent = billboardGui

	self.stateTextLabel = textLabel
end

-- Method to create the attack range visualization
function FSM:createAttackRangeVisualization()
	if self.attackRangeVisualization then
		self.attackRangeVisualization:Destroy()
		self.attackRangeVisualization = nil
	end
	
	-- Create the part to represent the attack range
	local attackRange = Instance.new("Part")
	attackRange.Name = "AttackRangeVisualization"
	attackRange.Shape = Enum.PartType.Ball -- Set the shape to a sphere
	attackRange.Size = Vector3.new(self.attackRange * 2, self.attackRange * 2, self.attackRange * 2)
	attackRange.Transparency = 0.8
	attackRange.Anchored = true
	attackRange.CanCollide = false
	attackRange.Material = Enum.Material.ForceField
	attackRange.Color = Color3.fromRGB(144, 238, 144)
	attackRange.CFrame = self.npc.HumanoidRootPart.CFrame -- Center the sphere on the NPC
	attackRange.Parent = self.npc

	self.attackRangeVisualization = attackRange
end

-- Update function to execute state-specific logic
function FSM:update()
	-- Update the position of the attack range visualization
	if self.attackRangeVisualization then
		self.attackRangeVisualization.CFrame = self.npc.HumanoidRootPart.CFrame * CFrame.Angles(math.pi / 2, 0, 0)
	end

	if self.human.Health <= 0 and self.currentState ~= "die" then
		self:transitionState("zero_hp")
	elseif self.currentState == "idle" then
		self:idleState()
	elseif self.currentState == "attack" then
		self:attackState()
	elseif self.currentState == "escape" then
		self:escapeState()
	elseif self.currentState == "die" then
		self:dieState()
	end
end

-- Main Loop: Create an instance of the FSM class for the NPC and update its state
local npc = script.Parent -- Assuming the script is attached to the NPC model
npc.Humanoid.DisplayName = "Doppelganger"
local enemyFSM = FSM.new(npc)

game:GetService("RunService").Stepped:Connect(function()
	enemyFSM:update()
end)
