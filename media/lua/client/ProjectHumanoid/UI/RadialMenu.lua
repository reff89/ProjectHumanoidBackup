
require("CommunityAPI")

-- Extend radial menu
function ISRadialMenu:onRightMouseDown(x, y)
	if self.NPCBackMenuFunc ~= nil then
		self.NPCBackMenuFunc(self.NPCArg1, self.NPCArg2, self.NPCArg3)
	else
		self:undisplay()
	end
end

--------

NPCRadialMenu = {}

function NPCRadialMenu.showRadialMenu(isNotRemoveIfVisible)
    local playerObj = getSpecificPlayer(0)

    local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
	if isPaused then return end

	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
	menu.NPCBackMenuFunc = nil
	menu.NPCArg1 = nil
	menu.NPCArg2 = nil
	menu.NPCArg3 = nil
	menu:clear()

	if menu:isReallyVisible() and not isNotRemoveIfVisible then
		if menu.joyfocus then
			setJoypadFocus(playerObj:getPlayerNum(), nil)
		end
		menu:undisplay()
		return
	end

	menu:setX(getPlayerScreenLeft(playerObj:getPlayerNum()) + getPlayerScreenWidth(playerObj:getPlayerNum()) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerObj:getPlayerNum()) + getPlayerScreenHeight(playerObj:getPlayerNum()) / 2 - menu:getHeight() / 2)

    --menu:addSlice("TEST", nil, nil, nil) -- name, texture, func, arg1, ...

	for i, npc in ipairs(NPCManager.characters) do
		if NPCUtils.getDistanceBetween(npc.character, playerObj) < 40 then
			local name = npc.character:getDescriptor():getForename() .. " " .. npc.character:getDescriptor():getSurname()
			if npc.nickname ~= nil then
				name = npc.nickname
			end
			menu:addSlice(name, getTexture("media/textures/NPC_Icon.png"), NPCRadialMenu.chooseCharacter, playerObj, npc)
		end
	end

	menu:addSlice("Show moodles", getTexture("media/textures/Moodle_Icon_Angry.png"), function() NPCManager.moodlesTimer = 300 end)

	menu:addSlice("Group Tasks", getTexture("media/textures/NPC_group.png"), NPCRadialMenu.groupTasks, playerObj)

	menu:addSlice("Choose sector...", getTexture("media/textures/NPC_chooseSector.png"), NPCRadialMenu.chooseSector, playerObj)

	if NPCManager.pvpTurnedOn then
		menu:addSlice("Turn Off PVP", getTexture("media/textures/NPC_PVP_ON.png"), function() 
			NPCManager.pvpTurnedOn = false 
			IsoPlayer.setCoopPVP(false)
		end)
	else
		menu:addSlice("Turn On PVP", getTexture("media/textures/NPC_PVP_OFF.png"), function() 
			NPCManager.pvpTurnedOn = true 
			IsoPlayer.setCoopPVP(true)			
		end)
	end
	
    menu:addToUIManager()

	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.groupTasks(playerObj)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.showRadialMenu
	menu.NPCArg1 = true
	menu.NPCArg2 = nil
	menu.NPCArg3 = nil
	menu:clear()

	menu:addSlice("Follow", getTexture("media/textures/NPC_Walk.png"), NPCRadialMenu.setFollow, npc, true, true)	
	menu:addSlice("Stop follow", getTexture("media/textures/NPC_Walk.png"), NPCRadialMenu.setFollow, npc, false, true)
	menu:addSlice("Find items", getTexture("media/textures/NPC_findItems.png"), NPCRadialMenu.FindItemsMenu, playerObj, npc, true)

	menu:addSlice("Set passive attack mode", getTexture("media/textures/NPC_peaceIcon.png"), NPCRadialMenu.AgressivePassiveAttackMode, npc, false, true)
	menu:addSlice("Set aggressive attack mode", getTexture("media/textures/NPC_AgressiveIcon.png"), NPCRadialMenu.AgressivePassiveAttackMode, npc, true, true)

	menu:addSlice("Reload weapon", getTexture("media/textures/NPC_Reload.png"), NPCRadialMenu.ReloadWeapon)

	menu:addSlice("Collect corpses", getTexture("media/textures/NPC_CARRY_BODY.png"), function()
		for _, char in ipairs(NPCManager.characters) do
			char.AI.command = "COLLECT_CORPSES"
		end
	end)

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.chooseSector(playerObj)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.showRadialMenu
	menu.NPCArg1 = true
	menu.NPCArg2 = nil
	menu.NPCArg3 = nil
	menu:clear()

	menu:addSlice("Choose base", getTexture("media/textures/NPC_base.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isBaseChoose = true
	end)

	menu:addSlice("Choose drop loot sectors...", getTexture("media/textures/NPC_drop.png"), NPCRadialMenu.chooseSecotorsDropLoot, playerObj)

	menu:addSlice("Choose farming sector", getTexture("media/textures/NPC_FARMING.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isFarmingChoose = true
	end)

	menu:addSlice("Choose cut wood sector", getTexture("media/textures/NPC_CUT_WOOD.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.cutWoodChoose = true
	end)

	menu:addSlice("Choose forage sector", getTexture("media/textures/NPC_FORAGE.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.forageChoose = true
	end)

	menu:addSlice("Choose collect corpses sector", getTexture("media/textures/NPC_CARRY_BODY.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.collectCorpsesChoose = true
	end)

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.chooseSecotorsDropLoot(playerObj)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.chooseSector
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = nil
	menu.NPCArg3 = nil
	menu:clear()

	menu:addSlice("Food", getTexture("media/textures/NPC_food_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "FOOD"
	end)

	menu:addSlice("Firearm", getTexture("media/textures/NPC_Guns_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "WEAPON"
	end)

	menu:addSlice("Clothing", getTexture("media/textures/NPC_clothing_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "CLOTHING"
	end)

	menu:addSlice("Meds", getTexture("media/textures/NPC_MedsIcon_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "MEDS"
	end)

	menu:addSlice("Bags", getTexture("media/textures/NPC_BagIcon_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "BAGS"
	end)

	menu:addSlice("Melee", getTexture("media/textures/NPC_KnifeIcon_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "MELEE"
	end)

	menu:addSlice("Literature", getTexture("media/textures/NPC_BooksIcon_ON.png"), function()
		NPCManager.chooseSector = true 
		NPCManager.sector = nil
		NPCManager.isDropLootChoose = true
		NPCManager.isDropLootType = "LITERATURE"
	end)

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.chooseCharacter(playerObj, npc)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.showRadialMenu
	menu.NPCArg1 = true
	menu.NPCArg2 = nil
	menu.NPCArg3 = nil
	menu:clear()

	if npc.AI:getType() == AI.Type.AutonomousAI then
		if npc.AI.TaskManager:getCurrentTaskName() ~= "Robbing" then
			if npc.AI.isRobbed then
				menu:addSlice("Command drop loot on floor", getTexture("media/textures/NPC_drop.png"), NPCRadialMenu.robDropLoot, npc)
				menu:addSlice("Command flee", getTexture("media/textures/NPC_FLEE.png"), NPCRadialMenu.robFlee, npc)
			else
				menu:addSlice("Rob", getTexture("media/textures/NPC_ROB.png"), NPCRadialMenu.rob, npc)
			end

			menu:addSlice("Invite to team", getTexture("media/textures/NPC_Invite.png"), NPCRadialMenu.inviteToTeam, npc)
		end
	else	
		menu:addSlice("Info", getTexture("media/textures/NPC_info.png"), NPCRadialMenu.characterInfo, npc)
	
		menu:addSlice("Tasks", getTexture("media/textures/NPC_tasks.png"), NPCRadialMenu.npcTasks, playerObj, npc)
	
		menu:addSlice("Stop tasks", getTexture("media/textures/NPC_Stop.png"), NPCRadialMenu.stopTasks, npc)
	
		menu:addSlice("NPC settings", getTexture("media/textures/NPC_settings.png"), NPCRadialMenu.npcSettings, playerObj, npc)
	
		menu:addSlice("Teleport to me", getTexture("media/textures/NPC_teleport.png"), NPCRadialMenu.teleportToMe, npc)

		menu:addSlice("Kick out", getTexture("media/textures/NPC_KICKOUT.png"), NPCRadialMenu.kickout, npc)
	end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.robDropLoot(npc)
	ISTimedActionQueue.clear(npc.character)
	npc.AI.robDropLoot = true
end

function NPCRadialMenu.robFlee(npc)
	ISTimedActionQueue.clear(npc.character)
	npc.AI.robFlee = true
end

function NPCRadialMenu.rob(npc)
	npc.AI.isRobbed = true
    npc.AI.robbedBy = getPlayer()

	npc.reputationSystem:updatePlayerRep(-800)
	npc:SayNote("Reputation [img=media/ui/ArrowDown.png]", NPCColor.Red)
end

function NPCRadialMenu.inviteToTeam(npc)
	NPCGroupManager:playerInviteToTeamNPC(npc)
end

function NPCRadialMenu.teleportToMe(npc)
	npc.character:setX(NPCRadialMenu.mainPlayer:getX())
	npc.character:setY(NPCRadialMenu.mainPlayer:getY())
	npc.character:setZ(NPCRadialMenu.mainPlayer:getZ())
end

function NPCRadialMenu.kickout(npc)
	npc:setAI(AI.Type.AutonomousAI) 	
	ISTimedActionQueue.clear(npc.character)
	npc.reputationSystem.playerRep = 100
end

function NPCRadialMenu.npcSettings(playerObj, npc)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.chooseCharacter
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = npc
	menu.NPCArg3 = nil
	menu:clear()

	if npc.AI.agressiveAttack then
		menu:addSlice("Set passive attack mode", getTexture("media/textures/NPC_peaceIcon.png"), NPCRadialMenu.AgressivePassiveAttackMode, npc, false, false)
	else
		menu:addSlice("Set aggressive attack mode", getTexture("media/textures/NPC_AgressiveIcon.png"), NPCRadialMenu.AgressivePassiveAttackMode, npc, true, false)
	end

	if npc:isUsingGun() then
		menu:addSlice("Set use mele", getTexture("media/textures/NPC_meleIcon.png"), NPCRadialMenu.NearFarAttackMode, npc, false)
	else
		menu:addSlice("Set use gun", getTexture("media/textures/NPC_gunIcon.png"), NPCRadialMenu.NearFarAttackMode, npc, true)
	end

	menu:addSlice("Set nickname", getTexture("media/textures/NPC_nickname.png"), NPCRadialMenu.setNickname, npc)

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.npcTasks(playerObj, npc)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.chooseCharacter
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = npc
	menu.NPCArg3 = nil
	menu:clear()

	if not npc.AI:isCommandFollow() then
		menu:addSlice("Follow", getTexture("media/textures/NPC_Walk.png"), NPCRadialMenu.setFollow, npc, true, false)	
	else
		menu:addSlice("Stop follow", getTexture("media/textures/NPC_Walk.png"), NPCRadialMenu.setFollow, npc, false, false)
	end
	
	if not npc.AI:isCommandStayHere() then
		menu:addSlice("Stay here ...", getTexture("media/textures/NPC_Stay.png"), NPCRadialMenu.setStay, npc, true)	
	else
		menu:addSlice("Relax", getTexture("media/textures/NPC_Stay.png"), NPCRadialMenu.setStay, npc, false)	
	end

	menu:addSlice("Find items", getTexture("media/textures/NPC_findItems.png"), NPCRadialMenu.FindItemsMenu, playerObj, npc, false)

	menu:addSlice("Sit", getTexture("media/textures/NPC_Sit.png"), NPCRadialMenu.Sit, npc)	
	menu:addSlice("Call", getTexture("media/textures/NPC_Call.png"), NPCRadialMenu.Call, npc)
	
	menu:addSlice("Talk", getTexture("media/textures/NPC_Talk.png"), NPCRadialMenu.Talk, npc)

	menu:addSlice("Drop loot", getTexture("media/textures/NPC_drop.png"), NPCRadialMenu.dropLoot, npc)

	menu:addSlice("Patrol", getTexture("media/textures/NPC_PATROL.png"), NPCRadialMenu.patrol, npc)

	menu:addSlice("Collect corpses", getTexture("media/textures/NPC_CARRY_BODY.png"), NPCRadialMenu.collectCorpses, npc)

	-- WASH
	local washYourself = ISWashYourself.GetRequiredWater(npc.character) > 0
	local washWeapon = false
	local washClothing = false
	local washClothingList = {}
	local washWeaponList = {}

	local clothingInventory = npc.character:getInventory():getItemsFromCategory("Clothing")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		-- Wasn't able to reproduce the wash 'Blooo' bug, don't know the exact cause so here's a fix...
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) then
			if washClothing == false then
				washClothing = true
			end
			table.insert(washClothingList, item)
		end
	end
	
    local weaponInventory = npc.character:getInventory():getItemsFromCategory("Weapon")
    for i=0, weaponInventory:size() - 1 do
        local item = weaponInventory:get(i)
        if item:hasBlood() then
            if washWeapon == false then
                washWeapon = true
            end
            table.insert(washWeaponList, item)
        end
	end

	if washYourself or washWeapon or washClothing then
		menu:addSlice("Wash", getTexture("media/textures/NPC_wash.png"), NPCRadialMenu.washMenu, playerObj, npc, washYourself, washWeapon, washClothing, washClothingList, washWeaponList)
	end
	

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.ReloadWeapon()
	for i, char in ipairs(NPCManager.characters) do
		char.AI.command = "RELOAD"
		char.AI.TaskArgs.isFullReload = true
		NPCRadialMenu.NearFarAttackMode(char, true)
	end
end

function NPCRadialMenu.washMenu(playerObj, npc, washYourself, washWeapon, washClothing, washClothingList, washWeaponList)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.npcTasks
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = npc
	menu.NPCArg3 = nil
	menu:clear()

	if washYourself then
		menu:addSlice("Wash yourself", getTexture("media/textures/NPC_wash.png"), NPCRadialMenu.washTask, npc, true, nil)
	end

	if washClothing then
		menu:addSlice("Wash clothing", getTexture("media/textures/NPC_wash.png"), NPCRadialMenu.washTask, npc, false, washClothingList)
	end

	if washWeapon then
		menu:addSlice("Wash weapon", getTexture("media/textures/NPC_wash.png"), NPCRadialMenu.washTask, npc, false, washWeaponList)
	end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.washTask(npc, isWashYourself, washList)
	npc.AI.command = "WASH"
	if isWashYourself then
		npc.AI.washArg = "Character"
	else
		npc.AI.washArg = washList
	end
end


function NPCRadialMenu.setNickname(npc)
	local name = npc.character:getDescriptor():getForename() .. " " .. npc.character:getDescriptor():getSurname()
	if npc.nickname then
		name = npc.nickname
	end
	local modal = ISTextBox:new(0, 0, 280, 180, "Set nickname", name, nil, NPCRadialMenu.onSetNickname, 0, npc.character, npc);
    modal:initialise();
    modal:addToUIManager();
end

function NPCRadialMenu:onSetNickname(button, character, npc)
	print(button)
    if button.internal == "OK" then
        if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then

			npc.nickname = button.parent.entry:getText()
			npc.username:updateName()
        end
    end
end

function NPCRadialMenu.characterInfo(npc)
	local characterInfo = NPC_ISCharacterInfoWindow:new(100,100,400,400,npc.character);
    characterInfo:initialise();
    characterInfo:addToUIManager();
	characterInfo:setVisible(true);
end

function NPCRadialMenu.stopTasks(npc)
	print("STOP TASKS")
	npc.AI.TaskManager:clear()
	ISTimedActionQueue.clear(npc.character)
	npc.character:NPCSetAttack(false)
    npc.character:NPCSetMelee(false)
    npc.character:NPCSetAiming(false)
    npc.character:setForceShove(false);
    npc.character:setAimAtFloor(false)
    npc.character:setVariable("bShoveAiming", false);
	npc.AI.command = nil
end

function NPCRadialMenu.setFollow(npc, bool, isGroupTask)
	if isGroupTask then
		for i, char in ipairs(NPCManager.characters) do
			if bool then
				char.AI.command = "FOLLOW"
			else
				char.AI.command = ""
			end
		end
	else
		if bool then
			npc.AI.command = "FOLLOW"
		else
			npc.AI.command = ""
		end
	end
end

function NPCRadialMenu.setStay(npc, bool)
	if bool then
		NPCManager.choosingStaySquare = true
		NPCManager.choosingStayNPC = npc
	else
		npc.AI.command = ""
		npc.AI.staySquare = nil
	end
end


function NPCRadialMenu.Call(npc)
	npc.character:facePosition(getPlayer():getX(), getPlayer():getY())
	getPlayer():Say("Hey!")
	npc:Say("Hey!", NPCColor.White)
end

function NPCRadialMenu.Talk(npc)
	npc.character:facePosition(getPlayer():getX(), getPlayer():getY())
	
	npc.AI.command = nil
	npc.AI.idleCommand = "TALK"
	npc.AI.TaskArgs.talkChar = getPlayer()
end

function NPCRadialMenu.dropLoot(npc)
	npc.AI.command = "DROP_LOOT"
end

function NPCRadialMenu.patrol(npc)
	NPCManager.patrolChoose = true
	NPCManager.patrolNPC = npc
	NPCGroupManager.patrolPoints[npc.ID] = {}
end

function NPCRadialMenu.collectCorpses(npc)
	npc.AI.command = "COLLECT_CORPSES"
end

function NPCRadialMenu.Sit(npc)
	npc.character:reportEvent("EventSitOnGround")
end

function NPCRadialMenu.AgressivePassiveAttackMode(npc, bool, isGroupTask)
	if isGroupTask then
		for i, char in ipairs(NPCManager.characters) do
			char.AI.agressiveAttack = bool
		end
	else
		npc.AI.agressiveAttack = bool
	end
	
end

function NPCRadialMenu.NearFarAttackMode(npc, bool)
	npc.forcePrimaryItem = nil
	npc.forceSecondaryItem = nil
	npc.AI.isUsingGunParam = bool
end

function NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.npcTasks
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = npc
	menu.NPCArg3 = nil
	menu:clear()

	if isGroupTask then
		local settings = ModData.getOrCreate("NPCGroupFindTaskSettings")

		if settings.Food then
			menu:addSlice("Food", getTexture("media/textures/NPC_food_ON.png"), NPCRadialMenu.setFindFood, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Food", getTexture("media/textures/NPC_food_OFF.png"), NPCRadialMenu.setFindFood, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Weapon then
			menu:addSlice("Firearm", getTexture("media/textures/NPC_Guns_ON.png"), NPCRadialMenu.setFindWeapon, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Firearm", getTexture("media/textures/NPC_Guns_OFF.png"), NPCRadialMenu.setFindWeapon, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Clothing then
			menu:addSlice("Clothing", getTexture("media/textures/NPC_clothing_ON.png"), NPCRadialMenu.setFindClothing, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Clothing", getTexture("media/textures/NPC_clothing_OFF.png"), NPCRadialMenu.setFindClothing, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Meds then
			menu:addSlice("Meds", getTexture("media/textures/NPC_MedsIcon_ON.png"), NPCRadialMenu.setFindMeds, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Meds", getTexture("media/textures/NPC_MedsIcon_OFF.png"), NPCRadialMenu.setFindMeds, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Bags then
			menu:addSlice("Bags", getTexture("media/textures/NPC_BagIcon_ON.png"), NPCRadialMenu.setFindBags, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Bags", getTexture("media/textures/NPC_BagIcon_OFF.png"), NPCRadialMenu.setFindBags, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Melee then
			menu:addSlice("Melee", getTexture("media/textures/NPC_KnifeIcon_ON.png"), NPCRadialMenu.setFindMelee, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Melee", getTexture("media/textures/NPC_KnifeIcon_OFF.png"), NPCRadialMenu.setFindMelee, playerObj, npc, true, isGroupTask, settings)
		end
	
		if settings.Literature then
			menu:addSlice("Literature", getTexture("media/textures/NPC_BooksIcon_ON.png"), NPCRadialMenu.setFindLiterature, playerObj, npc, false, isGroupTask, settings)	
		else
			menu:addSlice("Literature", getTexture("media/textures/NPC_BooksIcon_OFF.png"), NPCRadialMenu.setFindLiterature, playerObj, npc, true, isGroupTask, settings)
		end

		menu:addSlice("Find", getTexture("media/textures/NPC_findItems.png"), NPCRadialMenu.findItemsWhere, playerObj, npc, isGroupTask)
		menu:addSlice("Close", getTexture("media/textures/NPC_Stop.png"), NPCRadialMenu.closeFindItemsMenu)

	else
		if npc.AI.findItems.Food then
			menu:addSlice("Food", getTexture("media/textures/NPC_food_ON.png"), NPCRadialMenu.setFindFood, playerObj, npc, false)	
		else
			menu:addSlice("Food", getTexture("media/textures/NPC_food_OFF.png"), NPCRadialMenu.setFindFood, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Weapon then
			menu:addSlice("Firearm", getTexture("media/textures/NPC_Guns_ON.png"), NPCRadialMenu.setFindWeapon, playerObj, npc, false)	
		else
			menu:addSlice("Firearm", getTexture("media/textures/NPC_Guns_OFF.png"), NPCRadialMenu.setFindWeapon, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Clothing then
			menu:addSlice("Clothing", getTexture("media/textures/NPC_clothing_ON.png"), NPCRadialMenu.setFindClothing, playerObj, npc, false)	
		else
			menu:addSlice("Clothing", getTexture("media/textures/NPC_clothing_OFF.png"), NPCRadialMenu.setFindClothing, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Meds then
			menu:addSlice("Meds", getTexture("media/textures/NPC_MedsIcon_ON.png"), NPCRadialMenu.setFindMeds, playerObj, npc, false)	
		else
			menu:addSlice("Meds", getTexture("media/textures/NPC_MedsIcon_OFF.png"), NPCRadialMenu.setFindMeds, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Bags then
			menu:addSlice("Bags", getTexture("media/textures/NPC_BagIcon_ON.png"), NPCRadialMenu.setFindBags, playerObj, npc, false)	
		else
			menu:addSlice("Bags", getTexture("media/textures/NPC_BagIcon_OFF.png"), NPCRadialMenu.setFindBags, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Melee then
			menu:addSlice("Melee", getTexture("media/textures/NPC_KnifeIcon_ON.png"), NPCRadialMenu.setFindMelee, playerObj, npc, false)	
		else
			menu:addSlice("Melee", getTexture("media/textures/NPC_KnifeIcon_OFF.png"), NPCRadialMenu.setFindMelee, playerObj, npc, true)
		end
	
		if npc.AI.findItems.Literature then
			menu:addSlice("Literature", getTexture("media/textures/NPC_BooksIcon_ON.png"), NPCRadialMenu.setFindLiterature, playerObj, npc, false)	
		else
			menu:addSlice("Literature", getTexture("media/textures/NPC_BooksIcon_OFF.png"), NPCRadialMenu.setFindLiterature, playerObj, npc, true)
		end
	
		menu:addSlice("Find", getTexture("media/textures/NPC_findItems.png"), NPCRadialMenu.findItemsWhere, playerObj, npc, isGroupTask)
		menu:addSlice("Close", getTexture("media/textures/NPC_Stop.png"), NPCRadialMenu.closeFindItemsMenu)
	end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end


function NPCRadialMenu.setFindFood(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Food = bool
	else
		npc.AI.findItems.Food = bool
	end
	
	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindWeapon(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Weapon = bool
	else
		npc.AI.findItems.Weapon = bool
	end
	
	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindClothing(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Clothing = bool
	else
		npc.AI.findItems.Clothing = bool
	end
	
	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindMeds(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Meds = bool
	else
		npc.AI.findItems.Meds = bool
	end

	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindBags(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Bags = bool
	else
		npc.AI.findItems.Bags = bool
	end

	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindMelee(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Melee = bool
	else
		npc.AI.findItems.Melee = bool
	end

	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.setFindLiterature(playerObj, npc, bool, isGroupTask, settings)
	if isGroupTask then
		settings.Literature = bool
	else
		npc.AI.findItems.Literature = bool
	end

	NPCRadialMenu.FindItemsMenu(playerObj, npc, isGroupTask)
end

function NPCRadialMenu.findItemsWhere(playerObj, npc, isGroupTask)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu.NPCBackMenuFunc = NPCRadialMenu.FindItemsMenu
	menu.NPCArg1 = playerObj
	menu.NPCArg2 = npc
	menu.NPCArg3 = isGroupTask
	menu:clear()

	menu:addSlice("Near me", getTexture("media/textures/NPC_near.png"), NPCRadialMenu.findItemsDo, npc, "NEAR", isGroupTask)
	menu:addSlice("In area", getTexture("media/textures/NPC_InArea.png"), NPCRadialMenu.findItemsDo, npc, "IN_AREA", isGroupTask)

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()
	if JoypadState.players[playerObj:getPlayerNum()+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerObj:getPlayerNum(), menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end
end

function NPCRadialMenu.findItemsDo(npc, where, isGroupTask)
	if isGroupTask then
		for i, char in ipairs(NPCManager.characters) do
			if char.AI:getType() == AI.Type.PlayerGroupAI then
				local settings = ModData.getOrCreate("NPCGroupFindTaskSettings")
				char.AI.findItems.Food = settings.Food
				char.AI.findItems.Weapon = settings.Weapon
				char.AI.findItems.Clothing = settings.Clothing
				char.AI.findItems.Meds = settings.Meds
				char.AI.findItems.Bags = settings.Bags
				char.AI.findItems.Melee = settings.Melee
				char.AI.findItems.Literature = settings.Literature
				
				char.AI.command = "FIND_ITEMS"
				char.AI.TaskArgs = {}
				char.AI.TaskArgs.FIND_ITEMS_WHERE = where
			end
		end
	else
		npc.AI.command = "FIND_ITEMS"
		if type(npc.AI.TaskArgs) ~= "table" then
			npc.AI.TaskArgs = {}
		end
		npc.AI.TaskArgs.FIND_ITEMS_WHERE = where
	end
end

function NPCRadialMenu.closeFindItemsMenu()
end


local onKeyStartPressed = function(key)
	NPCRadialMenu.mainPlayer = getPlayer()
	if not NPCRadialMenu.mainPlayer then return end
	if NPCRadialMenu.mainPlayer:isDead() then return end
	if key == CommunityAPI.Client.ModSetting.GetModSettingValue("ProjectHumanoid", "RADIAL_MENU_KEY") then
		NPCRadialMenu.showRadialMenu(false)
	end
end


Events.OnKeyStartPressed.Add(onKeyStartPressed);