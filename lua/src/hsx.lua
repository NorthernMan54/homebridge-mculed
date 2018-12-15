--SAFETRIM

--[[

 -- hsx -- v0.1.0 public domain Lua RGB/HSV/HSL/HSI color conversion functions
 -- no warranty implied; use at your own risk

 -- author: Ilya Kolbin (iskolbin@gmail.com)
 -- url: github.com/iskolbin/lhsx

 -- Provides RGB<->HSV, RGB<->HSL and RGB<->HSI conversion functions.
 -- All color components are assumed to be normalized to 1.0.

 -- COMPATIBILITY

 -- Lua 5.1+, LuaJIT

 -- LICENSE
 -- See end of file for license information.

--]]

local min, max, abs = math.min, math.max, math.abs

local Hsx = {}

-- Used

function Hsx.rgb2hsv( r, g, b )
	local M, m = max( r, g, b ), min( r, g, b )
	local C = M - m
	local K = 1.0/(6.0 * C)
	local h = 0.0
	if C ~= 0.0 then
		if M == r then     h = ((g - b) * K) % 1.0
		elseif M == g then h = (b - r) * K + 1.0/3.0
		else               h = (r - g) * K + 2.0/3.0
		end
	end
  -- Hue should be in degrees
  h = math.floor(h*360+.5)
	return h, M == 0.0 and 0.0 or C / M, M
end

-- function Hsx.hsv2rgb( h, s, v )
--	local C = v * s
--	local m = v - C
--	local r, g, b = m, m, m
--	if h == h then
--		local h_ = (h % 1.0) * 6
--		local X = C * (1 - abs(h_ % 2 - 1))
--		C, X = C + m, X + m
--		if     h_ < 1 then r, g, b = C, X, m
--		elseif h_ < 2 then r, g, b = X, C, m
--		elseif h_ < 3 then r, g, b = m, C, X
--		elseif h_ < 4 then r, g, b = m, X, C
--		elseif h_ < 5 then r, g, b = X, m, C
--		else               r, g, b = C, m, X
--		end
--	end
--	return r, g, b
-- end

-- function Hsx.rgb2hsl( r, g, b )
--	local M, m = max( r, g, b ), min( r, g, b )
--	local C = M - m
--	local K = 1.0 / (6*C)
--	local h = 0
--	if C ~= 0 then
--		if M == r then     h = ((g - b) * K) % 1.0
--		elseif M == g then h = (b - r) * K + 1.0/3.0
--		else               h = (r - g) * K + 2.0/3.0
--		end
--	end
--	local l = 0.5 * (M + m)
--	local s = 0
--	if l > 0 and l < 1 then
--		s = C / (1-abs(l + l - 1))
--	end
--	return h, s, l
-- end

-- function Hsx.hsl2rgb( h, s, l )
--	local C = ( 1 - abs( l + l - 1 ))*s
--	local m = l - 0.5*C
--	local r, g, b = m, m, m
--	if h == h then
--		local h_ = (h % 1.0) * 6.0
--		local X = C * (1 - abs(h_ % 2 - 1))
--		C, X = C + m, X + m
--		if     h_ < 1 then r, g, b = C, X, m
--		elseif h_ < 2 then r, g, b = X, C, m
--		elseif h_ < 3 then r, g, b = m, C, X
--		elseif h_ < 4 then r, g, b = m, X, C
--		elseif h_ < 5 then r, g, b = X, m, C
--		else               r, g, b = C, m, X
--		end
--	end
--	return r, g, b
-- end

-- local NAN = 0/0

-- function Hsx.rgb2hsi( r, g, b )
--	local M, m = max( r, g, b ), min( r, g, b )
--	local C = M - m
--	local K = 1.0 / (6*C)
--	local h = NAN
--	if     C ~= 0 then
--		if M == r then     h = ((g - b) * K % 1.0)
--		elseif M == g then h = (b - r) * K + 1.0/3.0
--		else               h = (r - g) * K + 2.0/3.0
--		end
--	end
--	local i = (r + g + b) * (1.0/3.0)
--	local s = i == 0.0 and 0.0 or (1.0 - m/i)
--	return h, s, i
-- end

-- function Hsx.hsi2rgb( h, s, i )
--	local cos, PI2 = math.cos, math.pi*2
--	h = ( h % 1.0 )
--	local r, g, b
--	if     h <= 1.0/3.0 then
--		b = 1.0 - s
--		r = 1.0 + s*cos( h*PI2 )/cos( (1.0/6.0 - h)*PI2 )
--		g = 3.0 - r - b
--	elseif h <= 2.0/3.0 then
--		h = h - 1.0/3.0
--		r = 1.0 - s
--		g = 1.0 + s*cos( h*PI2 )/cos( (1.0/6.0 - h )*PI2 )
--		b = 3.0 - r - g
--	else
--		h = h - 2.0/3.0
--		g = 1.0 - s
--		b = 1.0 + s*cos( h*PI2 )/cos( (1.0/6.0 - h )*PI2 )
--		r = 3.0 - g - b
--	end
--	return i * r, i * g, i * b
-- end

-- Used

function Hsx.hslToRgb(h1, s1, l1)
  local g, r, b = color_utils.hsv2grb(h1, s1 * 2.55, l1 * 2.55)
  return r, g, b
end

return Hsx

--[[
------------------------------------------------------------------------------
-- This software is available under 2 licenses -- choose whichever you prefer.
-- ----------------------------------------------------------------------------
-- ALTERNATIVE A - MIT License
-- Copyright (c) 2018 Ilya Kolbin
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-- ------------------------------------------------------------------------------
-- ALTERNATIVE B - Public Domain (www.unlicense.org)
-- This is free and unencumbered software released into the public domain.
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
-- software, either in source code form or as a compiled binary, for any purpose,
-- commercial or non-commercial, and by any means.
-- In jurisdictions that recognize copyright laws, the author or authors of this
-- software dedicate any and all copyright interest in the software to the public
-- domain. We make this dedication for the benefit of the public at large and to
-- the detriment of our heirs and successors. We intend this dedication to be an
-- overt act of relinquishment in perpetuity of all present and future rights to
-- this software under copyright law.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ------------------------------------------------------------------------------
--]]
