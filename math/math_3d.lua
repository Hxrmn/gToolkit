module("zmath", package.seeall)

--------------------------
--VECTOR MATH-------------
--------------------------

MsgN("MATH 3D")

function VectorsToAngles(forward, right, up)
	local xyDist = math.sqrt( forward.x * forward.x + forward.y * forward.y );
	local angle = Angle()

	if xyDist > 0.001 then
		angle.y = math.atan2( forward.y, forward.x ) * 57.3
		angle.p = math.atan2( -forward.z, xyDist ) * 57.3
		angle.r = math.atan2( right.z, up.z ) * 57.3
	else
		angle.y = math.atan2( -right.x, right.y ) * 57.3
		angle.p = math.atan2( -forward.z, xyDist ) * 57.3
		angle.r = 0
	end

	return angle
end

function AxisVectors(angle)
	local v1 = Vector(1,0,0)
	local v2 = Vector(0,1,0)
	local v3 = Vector(0,0,1)

	v1:Rotate(angle)
	v2:Rotate(angle)
	v3:Rotate(angle)

	return v1, v2, v3
end

--------------------------
--PLANE-------------------
--------------------------

local planeMeta = {}
planeMeta.__index = planeMeta

function planeMeta:Identity()
	self.forward.x = 1
	self.forward.y = 0
	self.forward.z = 0

	self.right.x = 0
	self.right.y = 1
	self.right.z = 0

	self.up.x = 0
	self.up.y = 0
	self.up.z = 1
	return self
end

function planeMeta:FromEntity(e)
	self.forward = e:GetForward()
	self.right = e:GetRight()
	self.up = e:GetUp()
	self:SetPos(e:GetPos())
	return self
end

function planeMeta:Rotate(angle)
	self.forward:Rotate(angle)
	self.right:Rotate(angle)
	self.up:Rotate(angle)
end

function planeMeta:SetPos(pos)
	self.origin.x = pos.x
	self.origin.y = pos.y
	self.origin.z = pos.z
end

function planeMeta:SetAngles(angle)
	self.forward = angle:Forward()
	self.right = angle:Right()
	self.up = angle:Up()
	return self
end

function planeMeta:GetAngles()
	return VectorsToAngles(self.forward, self.right, self.up)
end

--Project a point onto a plane
function planeMeta:ProjectPoint(origin)
	local a = (self.origin - origin):Dot(self.up)
	local b = self.up:Dot(self.up)
	local c = a / b
	local v = origin + self.up * c

	return v, c
end

--Project a vector onto a plane
function planeMeta:ProjectVector(origin, normal)
	local a = (self.origin - origin):Dot(self.up)
	local b = normal:Dot(self.up)
	local c = a / b
	local v = origin + normal * c

	return v, c
end

function planeMeta:GetX(origin) return (origin - self.origin):Dot(self.forward) end
function planeMeta:GetY(origin) return (origin - self.origin):Dot(self.right) end
function planeMeta:GetZ(origin) return (origin - self.origin):Dot(self.up) end

function planeMeta:WorldToLocal(origin)
	local v = origin - self.origin
	local f = v:Dot(self.forward)
	local r = v:Dot(self.right)
	local u = v:Dot(self.up)

	return Vector(f,r,u)
end

function planeMeta:LocalToWorld(origin)
	local v = self.origin
	v = v + origin.x * self.forward
	v = v + origin.y * self.right
	v = v + origin.z * self.up

	return v
end

function planeMeta:CalcZRot()
	local r = self.up:Angle():Right()
	local theta = self.right:Dot(r)
	local cross = self.right:Cross(r):Dot(self.up)

	if theta > 1.0 or theta < -1.0 then theta = 180
	else theta = math.acos(theta) * 57.3 end
	if cross >= 0 then return -theta end

	return theta
end

function planeMeta:CalcYRot()
	local r = self.right:Angle():Up()
	local theta = self.up:Dot(r)
	local cross = self.up:Cross(r):Dot(self.right)

	if theta > 1.0 or theta < -1.0 then theta = 180
	else theta = math.acos(theta) * 57.3 end
	if cross >= 0 then return -theta end
	
	return theta
end

function planeMeta:IsInFront(origin)
	return self:GetZ(origin) >= 0
end

function planeMeta:IsFacing(vector)
	return vector:Dot(self.up) < 0
end

function Plane(origin)
	return setmetatable( {
		origin = origin or Vector(0,0,0),
		forward = Vector(1,0,0),
		right = Vector(0,1,0),
		up = Vector(0,0,1),
	}, planeMeta )
end

--------------------------
--QUATERNION--------------
--------------------------

local quatMeta = {}

function Quaternion(vx,vy,vz,vw)
	return setmetatable( {
		x = vx or 0,
		y = vy or 0,
		z = vx or 0,
		w = vw or 0,
	}, quatMeta )
end

function quatMeta.__index(self, i)
	if type(i) == "number" then
		if i == 1 then return self.x end
		if i == 2 then return self.y end
		if i == 3 then return self.z end
		if i == 4 then return self.w end
	else
		local g = rawget(self, i)
		if g then return g end

		return rawget(quatMeta, i)
	end
end

function quatMeta.__newindex(self, i, n)
	if type(i) == "number" then
		if i == 1 then self.x = n end
		if i == 2 then self.y = n end
		if i == 3 then self.z = n end
		if i == 4 then self.w = n end
	else
		rawset(self, i, n)
	end
end

function quatMeta.__eq(a, b)
	return (a.x == b.x) and (a.y == b.y) and (a.z == b.z) and (a.w == b.w)
end

function quatMeta:Conjugate(dst)
	dst = dst or Quaternion()

	dst.x = -self.x;
	dst.y = -self.y;
	dst.z = -self.z;
	dst.w = self.w;

	return dst
end

function quatMeta:Invert(dst)
	dst = dst or Quaternion()

	self:Conjugate(dst)
	local magnitudeSqr = self:Dot(self);
	if magnitudeSqr ~= 0 then
		local inv = 1.0 / magnitudeSqr;
		dst.x = dst.x * inv;
		dst.y = dst.y * inv;
		dst.z = dst.z * inv;
		dst.w = dst.w * inv;
	end

	return dst
end

function quatMeta:Normalize()
	local radius = self:Dot(self)
	if radius ~= 0 then
		radius = math.sqrt(radius);
		local iradius = 1.0/radius;
		self.x = self.x * iradius;
		self.y = self.y * iradius;
		self.z = self.z * iradius;
		self.w = self.w * iradius;
	end
	return radius
end

function quatMeta:QuaternionAlign( q, dst )
	dst = dst or Quaternion()

	local p = self

	local a = 0;
	local b = 0;
	local i = 0;

	for i = 1, 4 do
		a = a + (p[i]-q[i])*(p[i]-q[i]);
		b = b + (p[i]+q[i])*(p[i]+q[i]);
	end

	if a > b then
		for i = 1, 4 do 
			dst[i] = -q[i];
		end
	elseif dst ~= q then
		for i = 1, 4 do 
			dst[i] = q[i];
		end
	end

	return dst
end

function quatMeta:Add(other)
	local q2 = self:QuaternionAlign( other );

	self.x = self.x + q2.x;
	self.y = self.y + q2.y;
	self.z = self.z + q2.z;
	self.w = self.w + q2.w;

	return self
end

function quatMeta:Mult( other, dst )
	dst = dst or Quaternion()

	local p = self
	local q2 = self:QuaternionAlign( other );
	local qt = dst

	qt.x =  p.x * q2.w + p.y * q2.z - p.z * q2.y + p.w * q2.x;
	qt.y = -p.x * q2.z + p.y * q2.w + p.z * q2.x + p.w * q2.y;
	qt.z =  p.x * q2.y - p.y * q2.x + p.z * q2.w + p.w * q2.z;
	qt.w = -p.x * q2.x - p.y * q2.y - p.z * q2.z + p.w * q2.w;

	return dst
end

function quatMeta:AngleDiff( other )
	local qInv = other:Conjugate()
	local diff = Quaternion()
	self:Mult( qInv, diff )

	local sinang = math.sqrt( diff.x * diff.x + diff.y * diff.y + diff.z * diff.z )
	local angle = ( 2 * math.asin( sinang ) ) * 57.3
	return angle
end

function quatMeta:Dot(b)
	local a = self
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
end

function quatMeta:Blend( other, t, dst )
	other = self:QuaternionAlign( other );

	local qt = dst or Quaternion()
	local sclp = 1.0 - t
	local sclq = t
	for i=1, 4 do
		qt[i] = sclp * self[i] + sclq * other[i];
	end
	
	qt:Normalize()

	return qt
end

function quatMeta:Slerp( other, t, dst )
	local omega = 0 
	local cosom = 0 
	local sinom = 0 
	local sclp = 0 
	local sclq = 0

	other = self:QuaternionAlign( other );

	local qt = dst or Quaternion()
	local cosom = self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;

	if (1.0 + cosom) > 0.000001 then
		if (1.0 - cosom) > 0.000001 then
			omega = math.acos( cosom );
			sinom = math.sin( omega );
			sclp = math.sin( (1.0 - t)*omega) / sinom;
			sclq = math.sin( t*omega ) / sinom;
		else
			sclp = 1.0 - t;
			sclq = t;
		end
		for i=1, 4 do
			qt[i] = sclp * self[i] + sclq * other[i];
		end
	else
		qt[1] = -other[2]
		qt[2] = other[1]
		qt[3] = -other[4]
		qt[4] = other[3]

		sclp = math.sin( (1.0 - t) * (0.5 * math.pi))
		sclq = math.sin( t * (0.5 * math.pi))
		for i=1, 4 do
			qt[i] = sclp * self[i] + sclq * other[i];
		end
	end

	return qt
end

local _iangles = Angle(0,0,0)
function quatMeta:FromAngles(angles)
	_iangles.p = angles.p / 57.3
	_iangles.y = angles.y / 57.3
	_iangles.r = angles.r / 57.3

	angles = _iangles

	local sp = math.sin(angles.p * 0.5)
	local cp = math.cos(angles.p * 0.5)

	local sy = math.sin(angles.y * 0.5)
	local cy = math.cos(angles.y * 0.5)

	local sr = math.sin(angles.r * 0.5)
	local cr = math.cos(angles.r * 0.5)

	local srXcp = sr * cp
	local crXsp = cr * sp

	self.x = srXcp*cy-crXsp*sy; // X
	self.y = crXsp*cy+srXcp*sy; // Y

	local crXcp = cr * cp
	local srXsp = sr * sp;

	self.z = crXcp*sy-srXsp*cy; // Z
	self.w = crXcp*cy+srXsp*sy; // W (real component)

	return self
end

function quatMeta:FromVectors(forward, right, up)
	local trace = forward.x + right.y + up.z + 1.0
	if trace > 1.0000001 then
		self.x = right.z - up.y
		self.y = up.x - forward.z
		self.z = forward.y - right.x
		self.w = trace
	elseif forward.x > right.y and forward.x > up.z then
		trace = 1.0 + forward.x - right.y - up.z;
		self.x = trace;
		self.y = forward.y + right.x
		self.z = up.x + forward.z
		self.w = right.z - up.y
	elseif right.y > up.z then
		trace = 1.0 + right.y - forward.x - up.z;
		self.x = right.x + forward.y;
		self.y = trace;
		self.z = right.z + up.y;
		self.w = up.x - forward.z;
	else
		trace = 1.0 + up.z - forward.x - right.y;
		self.x = up.x + forward.z;
		self.y = right.z + up.y;
		self.z = trace;
		self.w = forward.y - right.x;
	end

	self:Normalize()
	return self
end

function quatMeta:ToVectors(forward, right, up)
	forward = forward or Vector()
	right = right or Vector()
	up = up or Vector()
	local q = self

	forward.x = 1.0 - 2.0 * q.y * q.y - 2.0 * q.z * q.z;
	forward.y = 2.0 * q.x * q.y + 2.0 * q.w * q.z;
	forward.z = 2.0 * q.x * q.z - 2.0 * q.w * q.y;

	right.x = 2.0 * q.x * q.y - 2.0 * q.w * q.z;
	right.y = 1.0 - 2.0 * q.x * q.x - 2.0 * q.z * q.z;
	right.z = 2.0 * q.y * q.z + 2.0 * q.w * q.x;

	up.x = 2.0 * q.x * q.z + 2.0 * q.w * q.y;
	up.y = 2.0 * q.y * q.z - 2.0 * q.w * q.x;
	up.z = 1.0 - 2.0 * q.x * q.x - 2.0 * q.y * q.y;

	return forward, right, up
end

function quatMeta:FromPlane(plane)
	return self:FromVectors(plane.forward, plane.right, plane.up)
end

function quatMeta:ToPlane(plane)
	plane = plane or Plane()

	self:ToVectors(plane.forward, plane.right, plane.up)
	return plane
end

local _staticR1 = Quaternion()
local _staticRDST = Quaternion()
function quatMeta:RotateAroundAxis(axis, angle)
	local q = _staticR1:FromAxis(axis, angle / 57.3)
	q = self:Mult(q, _staticRDST)

	self.x = q.x
	self.y = q.y
	self.z = q.z
	self.w = q.w
end

local _vectorForward = Vector(1,0,0)
local _vectorRight = Vector(0,1,0)
local _vectorUp = Vector(0,0,1)
function quatMeta:Rotate(angle)
	self:RotateAroundAxis(_vectorForward, angle.r)
	self:RotateAroundAxis(_vectorRight, angle.p)
	self:RotateAroundAxis(_vectorUp, angle.y)
end

local _staticPlane = Plane()
function quatMeta:ToAngles()
	self:ToVectors(
		_staticPlane.forward, 
		_staticPlane.right, 
		_staticPlane.up)

	return _staticPlane:GetAngles()
end

function quatMeta:RotateVector(v)
	local vn = v:GetNormal()

	local vq = Quaternion(vn.x, vn.y, vn.z, vn.w)

	local conjugate = self:Conjugate()
	local res = Quaternion()
	vq:Mult( conjugate, res )
	self:Mult( res, res )

	return Vector( res.x, res.y, res.z )
end

function quatMeta:FromAxis(vector, angle)
	angle = angle * 0.5
	
	local sinAngle = math.sin(angle)

	self.x = vector.x * sinAngle
	self.y = vector.y * sinAngle
	self.z = vector.z * sinAngle
	self.w = math.cos(angle)

	return self
end

function quatMeta:ToAxis()
	local axis = Vector()
	local angle = (2 * math.acos(self.w)) * 57.3;
	if angle > 180 then
		angle = angle - 360
	end
	axis.x = self.x;
	axis.y = self.y;
	axis.z = self.z;
	axis:Normalize()

	return axis, angle
end

local _staticConjugate = Quaternion()
local _staticQ1 = Quaternion()
local _staticQ2 = Quaternion()
local _staticQ3 = Quaternion()
function GetAngleDifference(a, b, q)
	_staticQ1:FromAngles(a)
	_staticQ2:FromAngles(b)

	_staticQ1:Conjugate(_staticConjugate)
	_staticConjugate:Mult(_staticQ2, _staticQ3)

	if q then
		q.x = _staticQ3.x
		q.y = _staticQ3.y
		q.z = _staticQ3.z
		q.w = _staticQ3.w
	end

	return VectorsToAngles(_staticQ3:ToVectors())
end

--------------------------
--Catmull-Rom Spline------
--------------------------

local _staticVecA = Vector()
local _staticVecB = Vector()
local _staticVecC = Vector()
local _staticVecD = Vector()
local _staticVecOut = Vector()
local _staticVecOut2 = Vector()
local _staticVecOut3 = Vector()

local function VectorScale(v, s, out)
	out.x = v.x * s
	out.y = v.y * s
	out.z = v.z * s
end

local function VectorAdd(a, b, out)
	out.x = a.x + b.x
	out.y = a.y + b.y
	out.z = a.z + b.z
end

function CatmullRomSpline(p1, p2, p3, p4, t, output)
	local tSqr = t*t*0.5;
	local tSqrSqr = t*tSqr;
	t = t * 0.5;

	output = output or _staticVecOut

	output.x = 0
	output.y = 0
	output.z = 0

	local a = _staticVecA
	local b = _staticVecB
	local c = _staticVecC
	local d = _staticVecD

	// matrix row 1
	VectorScale( p1, -tSqrSqr, a );		// 0.5 t^3 * [ (-1*p1) + ( 3*p2) + (-3*p3) + p4 ]
	VectorScale( p2, tSqrSqr*3, b );
	VectorScale( p3, tSqrSqr*-3, c );
	VectorScale( p4, tSqrSqr, d );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );
	VectorAdd( c, output, output );
	VectorAdd( d, output, output );

	// matrix row 2
	VectorScale( p1, tSqr*2,  a );		// 0.5 t^2 * [ ( 2*p1) + (-5*p2) + ( 4*p3) - p4 ]
	VectorScale( p2, tSqr*-5, b );
	VectorScale( p3, tSqr*4,  c );
	VectorScale( p4, -tSqr,    d );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );
	VectorAdd( c, output, output );
	VectorAdd( d, output, output );

	// matrix row 3
	VectorScale( p1, -t, a );			// 0.5 t * [ (-1*p1) + p3 ]
	VectorScale( p3, t,  b );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );

	// matrix row 4
	VectorAdd( p2, output, output );	// p2

	return output
end

function CatmullRomSplineTangent(p1, p2, p3, p4, t, output)
	local tOne = 3*t*t*0.5;
	local tTwo = 2*t*0.5;
	local tThree = 0.5;

	output = output or _staticVecOut2

	output.x = 0
	output.y = 0
	output.z = 0

	local a = _staticVecA
	local b = _staticVecB
	local c = _staticVecC
	local d = _staticVecD

	// matrix row 1
	VectorScale( p1, -tOne, a );		// 0.5 t^3 * [ (-1*p1) + ( 3*p2) + (-3*p3) + p4 ]
	VectorScale( p2, tOne*3, b );
	VectorScale( p3, tOne*-3, c );
	VectorScale( p4, tOne, d );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );
	VectorAdd( c, output, output );
	VectorAdd( d, output, output );

	// matrix row 2
	VectorScale( p1, tTwo*2,  a );		// 0.5 t^2 * [ ( 2*p1) + (-5*p2) + ( 4*p3) - p4 ]
	VectorScale( p2, tTwo*-5, b );
	VectorScale( p3, tTwo*4,  c );
	VectorScale( p4, -tTwo,    d );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );
	VectorAdd( c, output, output );
	VectorAdd( d, output, output );

	// matrix row 3
	VectorScale( p1, -tThree, a );			// 0.5 t * [ (-1*p1) + p3 ]
	VectorScale( p3, tThree,  b );

	VectorAdd( a, output, output );
	VectorAdd( b, output, output );

	return output
end

function DrawCatmullRomSpline(p1, p2, p3, p4, steps, color)
	steps = steps or 10

	local interval = 1/steps
	local t = 0
	for i=1, steps do
		local a = CatmullRomSpline(p1, p2, p3, p4, t, _staticVecOut)
		--local tangent = CatmullRomSplineTangent(p1, p2, p3, p4, t, _staticVecOut3)

		t = t + interval
		local b = CatmullRomSpline(p1, p2, p3, p4, t, _staticVecOut2)

		render.DrawLine( a, b, color or Color(0,255,0,255), true )
	end
end