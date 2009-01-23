local matrix = require("includes/matrix")
local mark = LoadShader("white")

local function line(x1,y1,x2,y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local cx = x1 + dx/2
	local cy = y1 + dy/2
	local rot = math.atan2(dy,dx)*57.3
	
	draw.RectRotated(cx,cy,math.sqrt(dx*dx + dy*dy),2,mark,rot)
end

function identity()
	return matrix {{1,0,0},{0,1,0},{0,0,1}}
end

function identityx(x,y,z)
	return matrix {{x},
				   {y},
				   {z}}
end

function m_translate(x,y,z,out)
	out = out + matrix {{x,0,0},{y,0,0},{z,0,0}}
	return out
end

function m_scale(x,y,z,out)
	out = out * matrix {{x,0,0},{0,y,0},{0,0,z}}
	return out
end

function m_rotate(pitch,yaw,roll,out)
	local cp = math.cos(pitch)
	local sp = math.sin(pitch)
	
	local cy = math.cos(yaw)
	local sy = math.sin(yaw)
	
	local cr = math.cos(roll)
	local sr = math.sin(roll)
	
	--X
	local x = matrix {{1,0,0},
					  {0,cp,sp},
					  {0,-sp,cp}}
	--Y
	local y = matrix {{cy,0,-sy},
					  {0,1,0},
					  {sy,0,cy}}
	--Z
	local z = matrix {{cr,sr,0},
					  {-sr,cr,0},
					  {0,0,1}}
					  
	out = out * (x * y * z)
	return out
end

function m_projection(e,d,out)
	out[1][1] = (d.x - e.x) * (e.z/d.z)
	out[2][1] = (d.y - e.y) * (e.z/d.z)
	return out
end

local vecs = {}
function newpos(x,y,z)
	--local mpos = Matrix:New(4)
	--mpos = mpos:Translate(x,y,z)
	local mpos = identityx(x,y,z)
	table.insert(vecs,{mat=mpos})
end
--local mouse = Matrix:New(4)
local manual = false
local shape = ""
local phase = 0

function sphere()
	shape = "sphere"
	--newpos(0,0,-.8)
	for t=0, 20 do
		local scalar = math.cos(((t*9) + phase) / 57.3)
		for i=0, 360, 25 do
			newpos(math.cos(i/57.3)*scalar,math.sin(i/57.3)*scalar,(t-10)/10)
		end
	end
	--newpos(0,0,.8)
end

--box
function box()
	shape = "box"
	newpos(-1,-1,-1)
	newpos(1,-1,-1)
	newpos(1,1,-1)
	newpos(-1,1,-1)

	newpos(-1,-1,1)
	newpos(1,-1,1)
	newpos(1,1,1)
	newpos(-1,1,1)
end

--square
function square()
	shape = "square"
	newpos(-1,0,1)
	newpos(-1,0,-1)
	newpos(1,0,-1)
	newpos(1,0,1)

	for i=-5,5 do
		newpos(i/5,0,-1)
		newpos(i/5,0,1)
	end
end

--sphere()
box()
--square()

local r = 0
local p = 0
local y = 0
local w,h = 320,240
local fov = 90
fov = fov / 2
fov = 1/math.tan(fov/2)

function getDepth(mat)
	if(mat == nil) then return end
	local az = (mat[3][1]*10) + 60
	if(az < 2) then az = 2 end
	return az
end

local function tweenvalue(tw,s,e)
	return s + (e - s)*tw
end

function vecline(v1,v2)
	local rez = 10
	if(v1 and v2) then
		local mt = v1.rmat
		local lmt = v2.rmat
		if(mt == nil) then return end
		if(lmt == nil) then return end
		if(mt[3][1] > 0 or lmt[3][1] > 0) then return end
		local x1 = (mt[1][1] * (w/2)) + w/2
		local y1 = (mt[2][1] * (h/2)) + h/2
		local d1 = getDepth(mt)
		local x2 = (lmt[1][1] * (w/2)) + w/2
		local y2 = (lmt[2][1] * (h/2)) + h/2
		local d2 = getDepth(lmt)
		
		local dx = x2-x1
		local dy = y2-y1
		
		--[[local incr = 1/rez
		for i=0,rez-1 do
			local tw = i/rez
			local depth = tweenvalue(tw,d1,d2)
			local x = tweenvalue(tw,x1,x1 + dx)
			local y = tweenvalue(tw,y1,y1 + dy)
			local px = tweenvalue(tw+incr,x1,x1 + dx)
			local py = tweenvalue(tw+incr,y1,y1 + dy)
		end]]
		draw.SetColor(1,1,1,1)
		line(x1,y1,x1+dx,y1+dy)
		
		--draw.SetColor(d1*5,d1*5,d1*5)
		--draw.Line(x1,y1,x1 + dx/2,y1 + dy/2)
		
		--draw.SetColor(d2*5,d2*5,d2*5)
		--draw.Line(x2,y2,x2 - dx/2,y2 - dy/2)
	end
end

local project = true
local mposition = matrix {{0,0,0},{0,0,0},{0,0,0}}
local translation = identityx(0,0,0)
local rotation = identity()
local lrotation = identity()
local scale = identityx(121,1,20)
local camera = identityx(0,0,3)

local tp = Vector(670.25,729.47,-30)
local xform = matrix {{tp.x,0,0},{tp.y,0,0},{tp.z,0,0}}
mposition = m_translate(tp.x,tp.y,tp.z,mposition)

function calculateMatricies()
	for k,v in pairs(vecs) do
		if(v.mat ~= nil) then
			local mt = v.mat
			mt = (lrotation * mt)
			mt = mt + mposition
			mt = (rotation * (mt - camera))
			
			local d = {x=mt[1][1],y=mt[2][1],z=mt[3][1]}
			local e = {x=0,y=0,z=fov}
			if(project) then mt = m_projection(e,d,mt) end

			mt[1][1] = mt[1][1] * -1.12
			mt[2][1] = mt[2][1] * -1.5
			
			mt[1][1] = mt[1][1] + 1
			mt[2][1] = mt[2][1] + 1
			
			v.rmat = mt
			mt = nil
		else
			v.rmat = identityx(0,0,0)
		end
	end
end

function drawLines()
	if(shape == "square") then
		vecline(vecs[1],vecs[2])
		vecline(vecs[2],vecs[3])
		vecline(vecs[3],vecs[4])
		vecline(vecs[1],vecs[4])
		
		for i=5,21,2 do
			vecline(vecs[i],vecs[i+1])
		end
	elseif(shape == "box") then
		vecline(vecs[1],vecs[2])
		vecline(vecs[2],vecs[3])
		vecline(vecs[3],vecs[4])
		vecline(vecs[1],vecs[4])
	
		vecline(vecs[5],vecs[6])
		vecline(vecs[6],vecs[7])
		vecline(vecs[7],vecs[8])
		vecline(vecs[5],vecs[8])

		vecline(vecs[1],vecs[5])
		vecline(vecs[2],vecs[6])
		vecline(vecs[3],vecs[7])
		vecline(vecs[4],vecs[8])
	else
		for k,v in pairs(vecs) do
			local last = vecs[k-1]
			if not (last) then last = vecs[#vecs] end
			if(last) then
				vecline(last,v)
			end
		end
	end
end

local dmx = 0
local dmy = 0
local lmx = GetMouseX()
local lmy = GetMouseY()
local function d2d()
	p = p + 0.004
	y = y + 0.004
	r = r + 0.001
	
	--vecs = {}
	--phase = phase + 1
	--sphere()
	
	--rotation:Identity()
	
	local o = _CG.viewOrigin
	local ang = VectorToAngles(_CG.refdef.forward)
	ang.x = -ang.x +90
	ang.y = -ang.y
	ang = ang / 57.3
	
	local f = _CG.refdef.forward
	local r = _CG.refdef.right
	local u = _CG.refdef.up
	
	--ang = VectorForward(ang)
	--print(tostring(ang) .. "\n")
	camera = identityx(o.x,o.y,o.z)
	rotation = identity()
	--rotation = m_rotate(ang.x,ang.y,ang.z,rotation)
	
	rotation = matrix {{-r.x,-r.y,-r.z},
					   {-u.x,-u.y,-u.z},
					   {-f.x,-f.y,-f.z},}
	
	dmx = GetMouseX() - lmx
	dmy = GetMouseY() - lmy
	
	local scalar = 1 + (math.sin(CurTime()*1)*0.006)
	--rotation = rotation:Rotate(0.004,0.004,0.001):Scale(scalar,scalar,scalar)
	--rotation = identity()
	--lrotation = m_rotate(-dmy/200,dmx/200,0,lrotation)
	--lrotation = m_scale(scalar,scalar,scalar,lrotation)
	lrotation = m_rotate(.05,.03,0,lrotation)
	calculateMatricies()
	
	draw.SetColor(1,1,1,1)
	drawLines()
	line(0,0,GetXMouse(),GetYMouse())
	
	lmx = GetMouseX()
	lmy = GetMouseY()
end
hook.add("Draw2D","cl_matrixtest1",d2d)

local function event(entity,event,pos,dir)
	if(event == EV_BULLET_HIT_WALL) then
		--PlaySound(explodeSound)
		local tp = pos
		mposition = identity()
		mposition = m_translate(tp.x,tp.y,tp.z,mposition)
	end
end
hook.add("EventReceived","vecdefine",event)