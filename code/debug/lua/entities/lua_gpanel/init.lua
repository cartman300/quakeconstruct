print("Loaded Init\n")

downloader.add("lua/entities/lua_gpanel/cl_init.lua")

local function writeVector(msg,v)
	message.WriteFloat(msg,v.x)
	message.WriteFloat(msg,v.y)
	message.WriteFloat(msg,v.z)
end

function ENT:Initialized()
	print("Ent Init\n")
	self.Entity:SetNextThink(LevelTime() + 1000)
	self.hp = 100
	self.nextheal = 0
	
	print("SPAWN ANGLE: " .. self.Entity:GetSpawnAngle() .. "\n")
	print("SPAWN ANGLE2: " .. tostring(self.Entity:GetAngles()) .. "\n")
	
	self.Entity:SetMins(Vector(-5,-5,-5))
	self.Entity:SetMaxs(Vector(5,5,5))
	self.Entity:SetClip(1)
	self.Entity:SetTakeDamage(true)
	self.Entity:SetHealth(1000)
	self.Entity:SetBounce(.7)
	--self.Entity:SetAngles(Vector(0,self.Entity:GetSpawnAngle(),0))
end

function GPanelMessage(self,str,client)
	--"panelfired " .. self.Entity:EntIndex() .. " " .. 1
	local args = string.Explode(" ",str)
	
	if(args[1] != "panelfired") then return end
	if(tonumber(args[2]) != self.Entity:EntIndex()) then return end
	local func = tonumber(args[3])

	for k,v in pairs(GetAllEntities()) do
		if(v:GetTargetName() == self.Entity:GetTarget()) then
			v:Fire()
		elseif(v:EntIndex() == self.Entity:GetTargetEnt():EntIndex()) then
			v:Fire()
		end
	end
end

function ENT:MessageReceived(str,client)
	
	GPanelMessage(self,str,client)

end

function ENT:Removed()

end

function ENT:Pain(other,b,take)

end

function ENT:SendSparks(p1,p2)

end

function ENT:Think()

end

function ENT:Touch(other,trace)

end