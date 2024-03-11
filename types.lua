-- NOTE: Not perfect, just works

local ffi = require("ffi")

local ffi_istype = ffi.istype

-- Complex numbers

local newComplexRaw = ffi.typeof("complex")
local function newComplex(re, im)
	re = re or 0
	im = im or 0
	return newComplexRaw(re, im)
end

local function clone(z)
	return newComplexRaw(z.re, z.im)
end

local function parts(z)
	return z.re, z.im
end

local i = newComplexRaw(0, 1)

local function complexAbs(z)
	return newComplexRaw(math.sqrt(z.re ^ 2 + z.im ^ 2), 0)
end

local function complexAbs2(z)
	return newComplexRaw(z.re ^ 2 + z.im ^ 2, 0)
end

local function complexArg(z)
	return newComplexRaw(math.atan2(z.im, z.re), 0)
end

local function realSqrtNegative(x)
	if x < 0 then
		return newComplexRaw(0, math.sqrt(-x))
	end
	return newComplexRaw(math.sqrt(x), 0)
end

local function complexSqrt(z)
	if z.im == 0 then
		return realSqrtNegative(z.re)
	end
	local absZ = complexAbs(z)
	return
		realSqrtNegative((absZ + z.re).re / 2) +
		i * z.im / math.abs(z.im) * realSqrtNegative((absZ - z.re).re / 2)
end

local function complexConjugate(z)
	return newComplexRaw(z.re, -z.im)
end

ffi.metatype("complex", {
	__add = function(a, b)
		if type(a) == "number" then
			return newComplexRaw(a + b.re, b.im)
		elseif type(b) == "number" then
			return newComplexRaw(a.re + b, a.im)
		else
			return newComplexRaw(a.re + b.re, a.im + b.im)
		end
	end,
	__sub = function(a, b)
		if type(a) == "number" then
			return newComplexRaw(a - b.re, -b.im)
		elseif type(b) == "number" then
			return newComplexRaw(a.re - b, a.im)
		else
			return newComplexRaw(a.re - b.im, a.re - b.im)
		end
	end,
	__unm = function(z)
		return newComplexRaw(-z.re, -z.im)
	end,
	__mul = function(a, b)
		if type(a) == "number" then
			return newComplexRaw(a * b.re, a * b.im)
		elseif type(b) == "number" then
			return newComplexRaw(a.re * b, a.im * b)
		else
			return newComplexRaw(
				a.re * b.re - a.im * b.im,
				a.im * b.re + a.re * b.im
			)
		end
	end,
	__div = function(a, b)
		if type(a) == "number" then
			return newComplexRaw(
				a * b.re / (b.re ^ 2 + b.im ^ 2),
				-a * b.im / (b.re ^ 2 + b.im ^ 2)
			)
		elseif type(b) == "number" then
			return newComplexRaw(
				a.re / b,
				a.im / b
			)
		else
			return newComplexRaw(
				(a.re * b.re + a.im * b.im) / (b.re ^ 2 + b.im ^ 2),
				(a.im * b.re - a.re * b.im) / (b.re ^ 2 + b.im ^ 2)
			)
		end
	end,
	__len = complexAbs,
	__tostring = function(z)
		return string.format("%f + $fi", z.re, z.im)
	end
})

local complex = setmetatable({
	new = newComplex,
	abs = complexAbs,
	abs2 = complexAbs2,
	arg = complexArg,
	sqrt = complexSqrt,
	parts = parts,
	clone = clone,
	conjugate = complexConjugate,
	i = i
}, {
	__call = function(_, re, im)
		return newComplex(re, im)
	end
})

-- Vectors
-- The B functions were ones based on my original understanding of complex vector length and complex vector dot

ffi.cdef([=[
	typedef struct {
		complex x, y;
	} vec2;
]=])

local rawnew = ffi.typeof("vec2")
local function new(x, y)
	x = x or 0
	y = y or x
	return rawnew(x, y)
end

local sqrt, sin, cos = complexSqrt, math.sin, math.cos

local function length(v)
	return sqrt(complexAbs2(v.x) + complexAbs2(v.y))
end

local function length2(v)
	return newComplexRaw(complexAbs2(v.x) + complexAbs2(v.y))
end

local function distance(a, b)
	return sqrt(complexAbs2(b.x - a.x) + complexAbs2(b.y - a.y))
end

local function distance2(a, b)
	return complexAbs2(b.x - a.x) + complexAbs2(b.y - a.y)
end

local function lengthB(v)
	local x, y = v.x, v.y
	return sqrt(x * x + y * y)
end

local function lengthB2(v)
	local x, y = v.x, v.y
	return x * x + y * y
end

local function distanceB(a, b)
	local x, y = b.x - a.x, b.y - a.y
	return sqrt(x * x + y * y)
end

local function distanceB2(a, b)
	local x, y = b.x - a.x, b.y - a.y
	return x * x + y * y
end

local function dot(a, b)
	return a.x * complexConjugate(a.y) + a.y * complexConjugate(b.y)
end

local function dotB(a, b)
	return a.x * b.x + a.y * b.y
end

local function normalise(v)
	return v / length(v)
end

local function normaliseB(v)
	return v / lengthB(v)
end

local function reflect(incident, normal)
	return incident - 2 * dot(normal, incident) * normal
end

-- k < 0 but k is complex?
-- local function refract(incident, normal, eta)
-- 	local ndi = dot(normal, incident)
-- 	local k = 1 - eta * eta * (1 - ndi * ndi)
-- 	if k < 0 then
-- 		return rawnew(0, 0)
-- 	else
-- 		return eta * incident - (eta * ndi + sqrt(k)) * normal
-- 	end
-- end

local function rotate(v, a)
	local x, y = v.x, v.y
	return rawnew(
		x * cos(a) - y * sin(a), 0,
		y * cos(a) + x * sin(a), 0
	)
end

local function fromAngle(a)
	return rawnew(cos(a), 0, sin(a), 0)
end

local function components(v)
	return v.x, v.y
end

local function componentsParts(v)
	return v.x.re, v.x.im, v.y.re, v.y.im
end

local function clone(v)
	return rawnew(v.x, v.y)
end

local function isComplex(object)
	return type(object) == "cdata" and ffi_istype("complex", object)
end

ffi.metatype("vec2", {
	__add = function(a, b)
		if type(a) == "number" or isComplex(a) then
			return rawnew(a + b.x, a + b.y)
		elseif type(b) == "number" or isComplex(b) then
			return rawnew(a.x + b, a.y + b)
		else
			return rawnew(a.x + b.x, a.y + b.y)
		end
	end,
	__sub = function(a, b)
		if type(a) == "number" or isComplex(a) then
			return rawnew(a - b.x, a - b.y)
		elseif type(b) == "number" or isComplex(b) then
			return rawnew(a.x - b, a.y - b)
		else
			return rawnew(a.x - b.x, a.y - b.y)
		end
	end,
	__unm = function(v)
		return rawnew(-v.x, -v.y)
	end,
	__mul = function(a, b)
		if type(a) == "number" or isComplex(a) then
			return rawnew(a * b.x, a * b.y)
		elseif type(b) == "number" or isComplex(b) then
			return rawnew(a.x * b, a.y * b)
		else
			return rawnew(a.x * b.x, a.y * b.y)
		end
	end,
	__div = function(a, b)
		if type(a) == "number" or isComplex(a) then
			return rawnew(a / b.x, a / b.y)
		elseif type(b) == "number" or isComplex(b) then
			return rawnew(a.x / b, a.y / b)
		else
			return rawnew(a.x / b.x, a.y / b.y)
		end
	end,
	__mod = function(a, b)
		if type(a) == "number" or isComplex(a) then
			return rawnew(a % b.x, a % b.y)
		elseif type(b) == "number" or isComplex(b) then
			return rawnew(a.x % b, a.y % b)
		else
			return rawnew(a.x % b.x, a.y % b.y)
		end
	end,
	__eq = function(a, b)
		local isVec2 = type(b) == "cdata" and ffi_istype("vec2", b)
		return isVec2 and a.x == b.x and a.y == b.y
	end,
	__len = length,
	__tostring = function(v)
		return "vec2(" .. tostring(v.x) ..  ", " .. tostring(v.y) .. ")"
	end
})

local vec2 = setmetatable({
	new = new,
	length = length,
	length2 = length2,
	distance = distance,
	distance2 = distance2,
	lengthB = lengthB,
	lengthB2 = lengthB2,
	distanceB = distanceB,
	distanceB2 = distanceB2,
	dot = dot,
	dotB = dotB,
	normalise = normalise,
	normaliseB = normaliseB,
	normalize = normalise,
	normalizeB = normaliseB,
	reflect = reflect,
	-- refract = refract,
	rotate = rotate,
	fromAngle = fromAngle,
	components = components,
	componentsParts = componentsParts,
	clone = clone
}, {
	__call = function(_, x, y)
		return new(x, y)
	end
})

return {complex = complex, vec2 = vec2}
