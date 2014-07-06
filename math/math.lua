module("zmath", package.seeall)

--Constants
LOG_2	 	= 0.6931471805599
PI 			= 3.1415926535898 --180 degrees
PI_OVER_2 	= 1.5707963267949 --90 degrees
DEG_2_RAD 	= PI / 180 --degrees * DEG_2_RAD = radians
RAD_2_DEG 	= 180 / PI --radians * RAD_2_DEG = degrees
EPSILON 	= 0.00001

--Rounds a value to zero based on threshold
function RoundToZero( value, threshold )

	threshold = threshold or EPSILON

	if math.abs(value) < threshold then value = 0 end
	return value

end

--Returns smaller number on the left
function CorrectMinMax( min, max )

	if max < min then return max, min end
	return min, max

end

--Determine how much two ranges overlap
function Overlap( min_a, max_a, min_b, max_b )

	min_a, max_a = CorrectMinMax( min_a, max_a )
	min_b, max_b = CorrectMinMax( min_b, max_b )

	local total_a = (max_a - min_a)
	local total_b = (max_b - min_b)

	--Inside
	if min_a >= min_b and max_a <= max_b then

		--Entire length
		return total_a
	end

	--Around
	if min_a < min_b and max_a > max_b then

		--Entire length
		return total_b
	end

	--Right side
	if min_a < min_b and max_a > min_b then

		--Right overlap
		return math.min(max_a - min_b, total_a)
	end

	--Left side
	if min_a < max_b and max_a > max_b then

		--Right overlap
		return math.min(max_b - min_a, total_a)
	end

	return 0

end

--Returns if a number is between two numbers.
function IsBetween( num, min, max )
	return num >= min and num <= max
end

--Returns an eased value between two numbers.
function Ease( origin, new, speed )
	return ( origin - new ) / speed
end

--Returns the average of an amount of numbers of a table
function Average( nums )

	if type( nums ) ~= "table" then return end

	local total = #nums
	local sum = 0

	for i=0, total do
		sum = sum + tonumber( nums[i] )
	end

	return sum / total

end

--Sine function ranging between min and max
function SinRange( min, max, theta )

	return min + (.5 * math.sin(theta) + .5) * ( max - min )

end

--Cosine function ranging between min and max
function CosRange( min, max, theta )
	
	return min + (.5 * math.cos(theta) + .5) * ( max - min )

end

--Take the given number to the largest power of two
function PowerOfTwo(n)

	return math.pow(2, math.ceil(math.log(n) / LOG_2))

end

--Random floating value between low and high
function Rand( low, high )

	return low + ( high - low ) * math.random()

end

--Rounds the number to the given decimal place or the nearest integer
function Round(num, idp)

	--Handle trivial case without multiplying exponents -zak
	if not idp then return math.floor(num + 0.5) end

	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
  
end

--Snap value
function Snap(num, steps)
	return math.floor(num / steps) * steps
end

--[a ----- b] 
--Interpolate between 'a' and 'b' by coefficient 'c'
function Lerp(a, b, c)
	return a + (b - a) * c
end

--[a1 --v-- a2]
--[b1 -------v------ b2]
--Map v from 'a' range to 'b' range
function Map(v, a1, a2, b1, b2)
	local a = (v - a1) / (a2 - a1)
	return a * (b2 - b1) + b1
end

--Wrap the value 'a' between 'min' and 'max'
--Default wraps between 0 and 1
function Wrap(a, min, max)
	min = min or 0
	max = max or 1
	return math.fmod(a, ( max - min ) ) + min
end

--Quadratic bezier curve thru a,b,c by coefficient 't'
function Quadratic(a, b, c, t)
	local mt = 1 - t
	local c1 = (mt * a + t * b)
	local c2 = (mt * b + t * c)
	return mt * c1 + t * c2
end

--Cubic bezier curve thru a,b,c,d by coefficient 't'
function Cubic(a, b, c, d, t)
	local mt = 1 - t
	local mts = mt ^ 2
	local c1 = (mt * mts) * a
	local c2 = (3*mts) * t * b
	local c3 = (3*mts) * t * c
	local c4 = (t ^ 3) * d
	return c1 + c2 + c3 + c4
end

--Cubic hermite spline thru p0 and p1 by coefficient 't'
function CubicHermite(p0, p1, m0, m1, t)
	local tS = t*t;
	local tC = tS*t;

	return (2*tC - 3*tS + 1)*p0 + (tC - 2*tS + t)*m0 + (-2*tC + 3*tS)*p1 + (tC - tS)*m1
end

--Catmull-rom spline thru p0 and p1 by coefficient 't'
function CatmullRom(a, b, c, d, t)
	local tS = t*t;
	local tC = tS*t;

	return .5 * ((2 * b) + (-a + c) * t + (2*a - 5*b + 4*c - d) * tS + (-a + 3*b - 3*c + d) * tC)
end

--Spline thru values by coefficient 't' to n'th degree
--WARNING: Overwrites values in table to reduce overhead
function NDSpline(values, t, count)
	count = count or #values
	if count > 1 then
		for i=1, count - 1 do
			values[i] = Lerp(values[i], values[i+1], t)
		end
		return NDSpline(values, t, count - 1)
	else
		return values[1]
	end
end

--Linear gradient
function Gradient(stops, t)
	local n = #stops

	if n == 0 then return 0 end

	local i=1
	while i < n do
		if stops[i][1] > t then break end
		i = i + 1
	end

	if i > n then return stops[n][2] end
	if i == 1 then return stops[1][2] end

	local a = stops[i-1]
	local b = stops[i]
	local c = Map(t, a[1], b[1], 0, 1)

	return Lerp(a[2], b[2], c)
end

MsgN("MATH")