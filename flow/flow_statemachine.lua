local mStateMachine = {}

print("STATE MACHINE")

module("zflow", package.seeall)

function StateMachine()

	return setmetatable({}, mStateMachine):Init()

end

function mStateMachine:Init()

	self.__states = {}
	self.__subCalls = {}
	self.__stateCall = false
	self.__nextState = nil
	self.__currentState = nil
	self.__nextThink = nil
	self.__nextStateArgs = nil
	self.__stateArgs = nil
	self.__isStateCall = false
	self.__isNewStateCall = false
	self.__stateStart = nil
	self.__stateReset = false
	self.__runwrapper = function()
		self.Run( self )
	end

	return self

end

function mStateMachine:RunState( state )

	if not state then return end

	local stateSubCall = self.__subCalls[self.__currentState]
	for call, params in pairs(stateSubCall) do

		if params.time < self:GetTime() then

			stateSubCall[call] = nil

			self.__nextStateArgs = params.args

			self:EnterState( call )
			self:RunState( self.__currentState )
			return

		end

	end

	self.__isNewStateCall = self.__stateCall == false
	self.__isStateCall = true
	self.__stateReset = false

	local b, e = pcall( self.__states[state], self, unpack( self.__stateArgs ) )

	if not self.__stateReset then
		
		self.__isStateCall = false
		self.__stateCall = true

	end
	
	if b then return end
	ErrorNoHalt( e .. '\n' )

end

function mStateMachine:GetTime()
	return self.__utime or CurTime()
end

function mStateMachine:Run(time)

	if time then
		self.__utime = time
	end

	self:RunState( self.__currentState )

	if self.__nextThink == nil or self.__nextThink > self:GetTime() then return end	
	
	self:EnterState( self.__nextState )

end

function mStateMachine:EnterState( state )

	if self.__currentState ~= state or not self.__wasCalledInState then
		self.__staticStart = self:GetTime()
	end

	local wstart = self.__nextThink or self:GetTime()

	self.__currentState = state
	self.__nextThink = nil
	self.__stateCall = false
	self.__subCalls[state] = self.__subCalls[state] or {}
	self.__stateArgs = self.__nextStateArgs
	self.__nextStateArgs = nil
	self.__stateStart = wstart
	self.__stateReset = true

end

function mStateMachine.__index( self, key )

	if key == "run" then return self.__runwrapper end
	if key == "started" then return self.__isNewStateCall end
	if key == "time" then return self:GetTime() - self.__stateStart end
	if key == "rtime" then return self:GetTime() - self.__staticStart end
	if key == "current" then return self.__currentState end

	local g = rawget( mStateMachine, key )
	if g then return g end

	g = rawget( self, key )
	if g then return g end

end

function mStateMachine.__newindex( self, key, value )
	
	if type( value ) ~= "function" or key == "__runwrapper" then 
		
		rawset( self, key, value )
		return 

	end

	self.__states[key] = value

end

function mStateMachine.__call( self, state, time, ... )

	if not state then 
		ErrorNoHalt( "StateMachine() first argument was 'nil'\n" )
		return
	end

	if not self.__states[state] then
		ErrorNoHalt( "State not found: " .. state )
		return 
	end

	local delay = self:GetTime() + ( time or 0 )
	local stateSubCall = self.__subCalls[self.__currentState]

	if self.__isStateCall and time and time ~= 0 then
		if not stateSubCall[state] then
			stateSubCall[state] = { time = delay, args = {...} }
		end
	end

	self.__wasCalledInState = self.__isStateCall
	self.__nextState = state
	self.__nextStateArgs = {...}

	if not time or time <= 0 then
		self.__nextThink = nil
		self:EnterState( state, 0 )
		if self.__isStateCall then
			self:RunState( self.__currentState )
		end
		return
	end

	self.__nextThink = delay

end