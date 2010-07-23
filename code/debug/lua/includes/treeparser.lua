local parser = {}
parser.keys = {}
parser.codebuffer = {}
parser.nodes = {}

function parser.keys.import(s)
	parser.parsefile(s)
end

function parser.checkkeys(n,line)
	local len = string.len(line)
	for k,v in pairs(parser.keys) do
		local f = string.find(line,k)
		local l = string.len(k)
		if(f ~= nil) then
			local val = string.sub(line,f+l,len)
			val = killGaps(val)
			local b,e = pcall(v,val)
			if not (b) then error(e) end
			return true
		end
	end
end

function parser.checkGrouping(k,v,f)
	if(f) then
		if(parser.level > 0) then
			--print(parser.level .. "\n")
			for i=1, parser.level do
				local lk = parser.locs[i]
				print("^1missing closing '}' for '{' at " .. lk[1] .. ":" .. lk[2] .. "\n")
			end
			error("")
		end
		return
	end
	local t = string.ToTable(v)
	for n,ch in pairs(t) do
		if(ch == "{") then
			parser.level = parser.level + 1
			parser.locs[parser.level] = {k,n}
		end
		if(ch == "}") then
			if(parser.level > 0) then
				parser.level = parser.level - 1
			else
				error("extra '}' at " .. k .. ":" .. n .. "\n")
			end
		end
	end
end

function parser.checkLevel(n,line)
	line = killGaps(line)
	local t = string.ToTable(line)
	local b = ""
	for n,ch in pairs(t) do
		b = b .. ch
		if(ch == "{") then
			b = string.sub(b,1,string.len(b)-1)
			parser.level = parser.level + 1
			--print("^2LEVEL: " .. parser.level .. "-'" .. b ..  "'\n")
			parser.codebuffer[parser.level] = {}
			parser.codebuffer[parser.level].title = b
			parser.codebuffer[parser.level].fields = {}
			return true
		end
		if(ch == "}") then
			local t = parser.codebuffer[parser.level]
			if(parser.level > 1) then
				parser.codebuffer[parser.level-1].fields[t.title] = t.fields
			else
				parser.nodes[t.title] = t.fields
			end
			--print("^3LOAD: " .. t.title .. "\n")
			parser.level = parser.level - 1
			return true
		end	
	end
end

function parser.checkValue(n,v)
	if(string.find(v,"\"")) then 
		v = string.Replace(v,"\"","")
		return true,v
	end
	if(firstChar(v) == "[" and lastChar(v) == "]") then
		v = string.sub(v,2,string.len(v)-1)
		v = v
		local tab = {}
		local t = string.Explode(",",v)
		for lk,lv in pairs(t) do
			local s,llv = parser.checkValue(n,lv)
			if(s) then
				tab[lk] = llv
			end
		end
		v = tab
		
		return true,v
	end
	if(parser.nodes[v] ~= nil) then
		return true,parser.nodes[v]
	end
	if(_G[v] ~= nil) then
		v = _G[v]
		return true,v
	end
	local n = tonumber(v)
	if(n ~= nil) then
		return true,n
	end
	
	
	return false
end

function parser.checkField(n,line)
	line = killGaps(line)
	local c = string.find(line,":")
	if not c then return end
	
	local k = string.sub(line,1,c-1)
	local v = string.sub(line,c+1,string.len(line))
	
	local s,v = parser.checkValue(n,v)
	if(s ~= true) then return end
	parser.codebuffer[parser.level].fields[k] = v
end

function parser.setup()
	parser.level = 0
	parser.locs = {}
	parser.codebuffer = {}
	parser.nodes = {}
end

function parser.parseLine(n,line)
	if(parser.checkLevel(n,line)) then return end
	if(parser.checkkeys(n,line)) then return end
	if(parser.checkField(n,line)) then return end
	--print(n .. ": " .. line .. "\n")
end

function parser.parse(str)
	parser.setup()
	local lines = string.Explode("\n",str)
	for k,v in pairs(lines) do
		parser.checkGrouping(k,v)
	end
	parser.checkGrouping(nil,nil,true)
	for k,v in pairs(lines) do
		parser.parseLine(k,v)
	end
	return parser.nodes
end

function parser.parsefile(file)
	local txt = packRead(file)
	if(txt == nil) then 
		print("^1Error: Could Not Read File: " .. file .. ".\n") 
		return nil
	end
	return parser.parse(txt)
end

ParseTreeFile = parser.parsefile
ParseTreeString = parser.parse