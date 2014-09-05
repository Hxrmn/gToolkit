--LZW COMPRESSION
--Coded by Zak Blystone

print("DATA LZW")

module("zdata", package.seeall)

function lzw_encode(sInput)
	local stBits, dict, result, s, ch, temp = 8, {}, {}, ""
	for i=0,255 do dict[string.char(i)] = i+1 end

	for i = 1, string.len(sInput) do
		ch = string.sub(sInput, i, i)
		temp = s..ch
		if dict[temp] then
			s = temp
		else
			table.insert(result, dict[s])
			dict[temp] = #result + 256
			s = ch
		end
	end
	table.insert(result, dict[s])

	local function maxBits(v) for i=1, 32 do if v < 2^i then return i end end end
	for i=1, #result do
		stBits = math.max(maxBits(result[i]), stBits)
	end

	local ch, iBit, str = 0, 0, string.char(stBits)

	for i=1, #result do
		for b=1, stBits do
			iBit = iBit + 1
			ch = ch + math.floor(result[i]/2^(b-1)) % 2 * (2^(iBit-1))
			if iBit == 8 then
				ch, iBit, str = 0, 0, str .. string.char(ch)
			end
		end
	end

	if iBit ~= 0 then str = str .. string.char(ch) end

	return str
end

function lzw_decode(str)
	local dict, result, entry, ch, temp, code = {}, {}
	for i=0,255 do dict[i+1] = string.char(i) end

	local data, code, iBit, stBits = {}, 0, 0, str:byte(i)

	for i=1, string.len(str)-1 do
		for b=1, 8 do
			iBit = iBit + 1
			code = code + math.floor(str:byte(i+1)/2^(b-1)) % 2 * (2^(iBit-1))

			if iBit == stBits then
				table.insert(data, code)
				code, iBit = 0, 0
			end
		end
	end

	temp = data[1]
	table.insert(result, dict[temp])

	for i = 2, #data do
		code = data[i]
		entry = dict[code]
		ch = entry and string.sub(entry, 1, 1) or string.sub(dict[temp], 1, 1)
		table.insert(result, entry or dict[temp]..ch)
		table.insert(dict, dict[temp]..ch)
		temp = code
	end

	return table.concat(result)
end