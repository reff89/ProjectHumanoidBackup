SurrenderTask = {}
SurrenderTask.__index = SurrenderTask

function SurrenderTask:new(character)
	local o = {}
	setmetatable(o, self)
	self.__index = self
		
    o.mainPlayer = getPlayer()
	o.character = character
	o.name = "Surrender"
	o.complete = false

    if o.character:getModData().NPC.AI.isRobbed then
        character:getModData().NPC:Say("Okay, i am surrend!", NPCColor.White)
    end

    o.robbedBy = o.character:getModData().NPC.AI.robbedBy

	return o
end


function SurrenderTask:isComplete()
	return self.complete
end

function SurrenderTask:stop()
end

function SurrenderTask:isValid()
    return self.character and self.robbedBy
end

function SurrenderTask:update()
    if not self:isValid() then 
        ISTimedActionQueue.clear(self.character)
        return false 
    end
    local actionCount = #ISTimedActionQueue.getTimedActionQueue(self.character).queue

    if actionCount == 0 then
        if self.isStartedFlee then
            self.character:getModData().NPC.AI.isRobbed = false
            self.character:getModData().NPC.AI.robbedBy = nil
            self.character:getModData().NPC.AI.robDropLoot = false
            self.character:getModData().NPC.AI.robFlee = false
            self.complete = true
            return
        end
    
        if self.character:getModData().NPC.AI.robDropLoot then
            local items = self.character:getInventory():getItems()
            for i=0, items:size()-1 do
                local item = items:get(i)
                ISTimedActionQueue.add(ISInventoryTransferAction:new(self.character, item, item:getContainer(), ISInventoryPage.floorContainer[1]))    
            end   

            local xx = self.character:getX()
            local yy = self.character:getY()
            local zz = self.character:getZ()
            for i=-1, 1 do
                for j=-1, 1 do
                    -- TODO add items in ScanSquaresSystem
                end
            end

            self.character:getModData().NPC.AI.robDropLoot = false 
        elseif self.character:getModData().NPC.AI.robFlee then
            local sq = self.robbedBy:getSquare()
            local currSq = self.character:getSquare()
            local dx = currSq:getX() - sq:getX()
            local dy = currSq:getY() - sq:getY()

            self.currentWalkAction = NPCWalkToAction:new(self.character, getCell():getGridSquare(currSq:getX() + dx*10, currSq:getY() + dy*10, currSq:getZ()), true)
		    ISTimedActionQueue.add(self.currentWalkAction)

            self.isStartedFlee = true
        else
            ISTimedActionQueue.add(SurrenderAction:new(self.character, self.mainPlayer))
        end
    end

    if NPCUtils.getDistanceBetween(self.robbedBy, self.character) > 10 then
        self.character:getModData().NPC.AI.isRobbed = false
        self.character:getModData().NPC.AI.robbedBy = nil
        self.character:getModData().NPC.AI.robDropLoot = false
        self.character:getModData().NPC.AI.robFlee = false
        self.complete = true
    end

    return true
end