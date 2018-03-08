--[[
The MIT License (MIT)

Copyright (c) 2017 throwarray

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
]]

-- Clear table
function Clear(a,_p)
	local p=_p or pairs
	if a then
		for k,v in p(a) do a[k]=nil end
		return a
	else return {} end
end

function Accumulator(len,acl)
	-- (re)constructor
	local a=acl or {}
	if a.done==nil or a.done==true then
		if a.value == nil then a.value='' end
		a.meta=Clear(a.meta)
		a.idx=0
		a.done=false
		a.len=tonumber(len)
	end
	return a
end

-- Take one until accumulator finished
function Accumulate(a,index,char,done)
	if not a.done then a.idx=a.idx+1
		a.done=done(a,index,char) or false
	end
	return a
end

-- Take one until space or end of input
local function A1(a,i,char)
	if char==" " then return true end
	a.value=a.value..char
	return i==a.len
end

-- Take one until space if not quoted, or end of input
local function A2(a,i,char,bool) bool=false
	if a.meta.quoted then
		if char=="\\" then a.meta.escaped=true
		elseif a.meta.escaped then
			if char=="`" then a.value=a.value..char
			else a.value=a.value.."\\"..char end
			a.meta.escaped=false return i==a.len
		elseif char=="`" then a.meta.quoted=false else bool=true end
	elseif char=="`" then a.meta.quoted=true return i==a.len
	elseif char==" " then return true else bool=true end
	if bool or i==a.len then a.value=a.value..char return i==a.len end
end

-- Parse commands from input
function ParseCommandInput(input,_acm)
	local len=string.len(input)
	local acm=_acm or {}

	acm.value=''
	acm.stage=0
	acm.args=Clear(acm.args,ipairs)
	acm.commands=Clear(acm.commands)

	for i=1,len do
		if acm.stage==0 then
			if Accumulate(
				Accumulator(len,acm),i,string.sub(input,i,i),A1
			).done then
				acm.command=acm.value
				table.insert(acm.args,acm.command)
				acm.stage=1 -- next
				acm.idx=0
				acm.value=''
				acm.commands[acm.command]=''
			end
		elseif acm.stage==1 then
			local sub=string.sub(input,i,i)
			if acm.idx==0 and sub=="-" then
				acm.stage=0
				acm.command=nil
				acm.value=sub
			elseif Accumulate(Accumulator(len,acm),i,sub,A2).done then
				acm.commands[acm.command]=acm.value
				acm.stage=0 -- reset
				acm.command=nil
				acm.value=''
			end
		end
	end

	return acm
end

---- NOTE
	-- local input='-y dog -w `\\`fox\\`` -a -b-c -d -e'
	-- local commands = ParseCommandInput(input,{}).commands
	-- for k,v in pairs(commands) do print(k..','..v) end

---- TODO MORE TESTS

---- IDEA Join chars and recycle array
	-- function Join(p)
	-- 	local str=''
	-- 	for k,v in ipairs(p) do
	-- 		p[k]=nil
	-- 		str=str..v
	-- 	end
	-- 	return str
	-- end
