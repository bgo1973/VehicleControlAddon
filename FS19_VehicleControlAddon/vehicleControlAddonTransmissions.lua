function vcaClass(subClass, baseClass)
	if baseClass == nil then 
		return { __metatable = subClass, __index  = subClass }
	end 
	return { __metatable = subClass, __index = baseClass }
end

vehicleControlAddonTransmissionBase = {}
vehicleControlAddonTransmissionBase_mt = vcaClass(vehicleControlAddonTransmissionBase)

vehicleControlAddonTransmissionBase.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }


function vehicleControlAddonTransmissionBase:new( mt, name, noGears, timeGears, rangeGearOverlap, timeRanges, gearRatios, gearTexts, rangeTexts )
	local self = {}

	if mt == nil then 
		setmetatable(self, vehicleControlAddonTransmissionBase_mt)
	else 
		setmetatable(self, mt)
	end 

	self.name             = name 
	self.numberOfGears    = noGears 
	self.numberOfRanges   = 1 + #rangeGearOverlap
	self.rangeGearFromTo  = {} 
	local ft = { from = 1, to = self.numberOfGears, ofs = 0 }
	local i  = 1
	while true do 
		table.insert( self.rangeGearFromTo, { from = ft.from, to = ft.to, ofs = ft.ofs, overlap = rangeGearOverlap[i] } )
		if rangeGearOverlap[i] == nil then 
			break 
		end 
		ft.from = ft.from + self.numberOfGears - rangeGearOverlap[i]
		ft.to   = ft.to   + self.numberOfGears - rangeGearOverlap[i]
		ft.ofs  = ft.ofs  + self.numberOfGears - rangeGearOverlap[i]
		i       = i + 1
	end 
	self.changeTimeGears  = timeGears
	self.changeTimeRanges = timeRanges
	local n = self.rangeGearFromTo[self.numberOfRanges].ofs + self.numberOfGears 
	self.gearRatios       = {}
	for i=1,n do 		
		if gearRatios == nil then 
			r = vehicleControlAddonTransmissionBase.gearRatios[i] 
		else 
			r = gearRatios[i]
		end 
		if r == nil then	
			print("Error: not enough gear ratios provided for transmission "..tostring(name))
			r = 1
		end 
		table.insert( self.gearRatios, r )
	end 

	if gearTexts == nil then 
		if     self.numberOfGears <= 1 then 
			self.gearTexts = { "" } 
		elseif self.numberOfRanges <= 4 or self.numberOfGears > 4 then 
			self.gearTexts = {} 
			for i=1,self.numberOfGears do 
				self.gearTexts[i] = tostring(i) 
			end 
		elseif self.numberOfGears == 2 then 
			self.gearTexts = { "L", "H" }
		elseif self.numberOfGears == 3 then 
			self.gearTexts = { "L", "M", "H" }
		else 
			self.gearTexts = { "LL", "L", "M", "H" }
		end 
	else 
		self.gearTexts = gearTexts 
	end 

	if rangeTexts == nil then 
		if     self.numberOfRanges <= 1 then 
			self.rangeTexts = { "" } 
		elseif self.numberOfRanges > 4 then 
			self.rangeTexts = {} 
			for i=1,self.numberOfRanges do 
				self.rangeTexts[i] = tostring(i) 
			end 
		elseif self.numberOfRanges == 2 then 
			self.rangeTexts = { "L", "H" }
		elseif self.numberOfRanges == 3 then 
			self.rangeTexts = { "L", "M", "H" }
		else 
			self.rangeTexts = { "LL", "L", "M", "H" }
		end 
	else 
		self.rangeTexts = rangeTexts 
	end 

	return self
end 

function vehicleControlAddonTransmissionBase:delete() 
	self.rangeGearFromTo = nil 
	self.gearTexts       = nil 
	self.rangeTexts      = nil
	self.gearRatios      = nil 
	self.vehicle         = nil 
end 

function vehicleControlAddonTransmissionBase:setVehicle( vehicle )
	self.vehicle = vehicle 
end

function vehicleControlAddonTransmissionBase:initGears( noEventSend )	
	local initGear = false 
	if     self.vehicle.vcaGear == 0 then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
		self.vehicle:vcaSetState( "vcaRange", self.numberOfRanges, noEventSend )			
	elseif self.vehicle.vcaGear < 1 then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
	elseif self.vehicle.vcaGear > self.numberOfGears then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", self.numberOfGears, noEventSend )
	end 
	if     self.vehicle.vcaRange < 1 then   
		initGear = true 
		self.vehicle:vcaSetState( "vcaRange", 1, noEventSend )
	elseif self.vehicle.vcaRange > self.numberOfRanges then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaRange", self.numberOfRanges, noEventSend )
	end 
	return initGear 
end 

function vehicleControlAddonTransmissionBase:getName()
	return self.name 
end 

function vehicleControlAddonTransmissionBase:getGearText( gear, range )
	if self.rangeTexts[range] ~= nil and self.gearTexts[gear] ~= nil then 
		return self.rangeTexts[range].." "..self.gearTexts[gear]
	elseif self.rangeTexts[range] ~= nil then 
		return self.rangeTexts[range] ~= nil 
	elseif self.gearTexts[gear] then 
		return self.gearTexts[gear]
	end 
	return ""
end 

function vehicleControlAddonTransmissionBase:grindingGears()
	if vehicleControlAddon.grindingSample ~= nil then 
		playSample( vehicleControlAddon.grindingSample, 1, 1, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:gearShiftSound()
	if vehicleControlAddon.gearShiftSample ~= nil then 
		playSample( vehicleControlAddon.gearShiftSample, 1, 1, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:powerShiftSound()
	if self.vehicle ~= nil and self.vehicle.spec_lights ~= nil and self.vehicle.spec_lights.samples ~= nil and self.vehicle.spec_lights.samples.turnLight then 
		g_soundManager:playSample(self.vehicle.spec_lights.samples.turnLight)
	end
end

function vehicleControlAddonTransmissionBase:gearUp()
	vehicleControlAddon.debugPrint(tostring(self.name)..", gearUp: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
	self.vehicle:vcaSetState("vcaShifterIndex", 0)
	if self.vehicle.vcaGear < self.numberOfGears then 
		if self.changeTimeGears > 100 then 
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaGear", self.vehicle.vcaGear + 1 )
		vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
	end 
end 

function vehicleControlAddonTransmissionBase:gearDown()
	self.vehicle:vcaSetState("vcaShifterIndex", 0)
	if self.vehicle.vcaGear > 1 then 
		if self.changeTimeGears > 100 then 
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaGear", self.vehicle.vcaGear - 1 )
	end 
end 

function vehicleControlAddonTransmissionBase:rangeUp()
	vehicleControlAddon.debugPrint(tostring(self.name)..", rangeUp: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
	if self.vehicle.vcaRange < self.numberOfRanges then 
		if self.changeTimeRanges > 100 then
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		local o
		if self.vehicle.vcaShifterIndex <= 0 and self.rangeGearFromTo[self.vehicle.vcaRange] ~= nil then 
			o = self.rangeGearFromTo[self.vehicle.vcaRange].overlap
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange + 1 )
		if o ~= nil then 
			o = self.numberOfGears - o - 1
			self.vehicle:vcaSetState( "vcaGear", math.max( 1, self.vehicle.vcaGear - o ) )
		end 
		vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
	end 
end 

function vehicleControlAddonTransmissionBase:rangeDown()
	if self.vehicle.vcaRange > 1 then 
		if self.changeTimeRanges > 100 then
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange - 1 )
		local o
		if self.vehicle.vcaShifterIndex <= 0 and self.rangeGearFromTo[self.vehicle.vcaRange] ~= nil then 
			o = self.rangeGearFromTo[self.vehicle.vcaRange].overlap
		end 
		if o ~= nil then 
			o = self.numberOfGears - o - 1
			self.vehicle:vcaSetState( "vcaGear", math.min( self.numberOfGears, self.vehicle.vcaGear + o ) )
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:splitGearsForShifter()
	return true 
end 

function vehicleControlAddonTransmissionBase:gearShifter( number, isPressed )
	if isPressed then 
		local goFwd = nil 
		local list  = self:getGearShifterIndeces()
		local num2  = 0
		
		if number == 7 then 
			if not self.vehicle.vcaShuttleCtrl then 
				return 
			end 
			
			self.vehicle.vcaShifter7isR1 = true 
			goFwd = false 
			
			if self:splitGearsForShifter() then 
				num2 = 2
				for i,l in pairs(list) do  
					if i > 1 and l > self.vehicle.vcaLaunchGear then 
						break 
					end 
					num2 = i  
				end 
				if not self.vehicle.vcaShifterLH and num2 > 1 then 
					num2 = num2 - 1
				elseif self.vehicle.vcaShifterLH and num2 == 1 then 
					num2 = 2
				end 
			else 
				if self.vehicle.vcaShifterLH then 
					num2 = number 
				else 
					num2 = number - 6 
				end 
			end 
		else			
			if self.vehicle.vcaShuttleCtrl and self.vehicle.vcaShifter7isR1 == nil then 
				self.vehicle.vcaShifter7isR1 = true 
			end 
			if self.vehicle.vcaShifter7isR1 then 
				goFwd = true 
			end 
			
			if self:splitGearsForShifter() then 
				num2 =  number + number 
				if not self.vehicle.vcaShifterLH and num2 > 1 then 
					num2 = num2 - 1
				end 
			else 
				if self.vehicle.vcaShifterLH then 
					num2 = number + 6 
				else 
					num2 = number 
				end 
			end 
		end 
		
		local index = list[num2] 
		if index == nil then 
			print("Cannot find correct gear for shifter position "..tostring(number))
			return 
		end 
		
		local g, r = self:getBestGearRangeFromIndex( self.vehicle.vcaGear, self.vehicle.vcaRange, index )
		
		if not ( self.vehicle.vcaAutoClutch ) and self.vehicle.vcaClutchPercent < 1
				and ( ( g ~= self.vehicle.vcaGear  and self.changeTimeGears  > 100 )
					 or ( r ~= self.vehicle.vcaRange and self.changeTimeRanges > 100 ) ) then 
			self:grindingGears()
		else 
			self.vehicle:vcaSetState( "vcaShifterIndex", number )
			self.vehicle:vcaSetState( "vcaGear", g )
			self.vehicle:vcaSetState( "vcaRange", r )
			self.vehicle:vcaSetState( "vcaNeutral", false )
			if goFwd ~= nil then
				self.vehicle:vcaSetState( "vcaShuttleFwd", goFwd )
			end
		end 
	else 
		self.vehicle:vcaSetState( "vcaNeutral", true )
		if self.vehicle.spec_motorized.motor.vcaLoad ~= nil then  
			self.vehicle:vcaSetState("vcaBOVVolume",self.vehicle.spec_motorized.motor.vcaLoad)
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:getGearShifterIndeces()
	if self.gearShifterIndeces == nil then 
		self.gearShifterLH = highRange
		local numGears = self:getNumberOfRatios()	
		local offset   = 0
		offset = math.max( numGears - 12 )	
		self.gearShifterIndeces = {} 
		for i=1,12 do 
			table.insert( self.gearShifterIndeces, math.max( 1, i + offset ) )
		end 
	end 
			
	return self.gearShifterIndeces
end 

function vehicleControlAddonTransmissionBase:getGearRatio( index )
	return self.gearRatios[index]
end 

function vehicleControlAddonTransmissionBase:getNumberOfRatios()
	return table.getn( self.gearRatios )
end 

function vehicleControlAddonTransmissionBase:getRatioIndex( gear, range )
	if gear == nil or range == nil or self.rangeGearFromTo[range] == nil then 
		return 0
	end
	return self.rangeGearFromTo[range].ofs + gear 
end 

function vehicleControlAddonTransmissionBase:getBestGearRangeFromIndex( oldGear, oldRange, index )
	local i = self:getRatioIndex( oldGear, oldRange )
	
	if index == nil or i == index then 
		return oldGear, oldRange 
	end 
	
	local g = oldGear 
	local r = oldRange 
	
	while true do 
		if self.rangeGearFromTo[r] ~= nil then 
			g = index - self.rangeGearFromTo[r].ofs 
			if 1 <= g and g <= self.numberOfGears then 
				return g, r 
			end 
		end 
		if i < index then 
			r = r + 1 
			if r > self.numberOfRanges then 
				return self.numberOfGears, self.numberOfRanges 
			end 
		else 
			r = r - 1 
			if r < 1 then 
				return 1, 1
			end 
		end 
	end 
	
	return 1, self.numberOfRanges
end 

function vehicleControlAddonTransmissionBase:getRatioIndexListOfGear( gear )
	local list = {}
	for i,r in pairs(self.rangeGearFromTo) do 
		table.insert( list, gear + r.ofs ) 
	end 
	return list 
end 

function vehicleControlAddonTransmissionBase:getRatioIndexListOfRange( range )
	if self.rangeGearFromTo[range] == nil then 
		return {} 
	end 
	list = {}
	for i=self.rangeGearFromTo[range].from,self.rangeGearFromTo[range].to do	
		table.insert( list, i )
	end 
	return list
end 

function vehicleControlAddonTransmissionBase:actionCallback( actionName, keyStatus )
	vehicleControlAddon.debugPrint(tostring(self.name)..": "..actionName)
	if     actionName == "vcaGearUp"   then
		self:gearUp()
	elseif actionName == "vcaGearDown" then
		self:gearDown()
	elseif actionName == "vcaRangeUp"  then
		self:rangeUp()
	elseif actionName == "vcaRangeDown"then
		self:rangeDown()
	elseif actionName == "vcaShifter1" then
		self:gearShifter( 1, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter2" then
		self:gearShifter( 2, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter3" then
		self:gearShifter( 3, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter4" then
		self:gearShifter( 4, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter5" then
		self:gearShifter( 5, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter6" then
		self:gearShifter( 6, keyStatus >= 0.5 )
	elseif actionName == "vcaShifter7" then 
		self:gearShifter( 7, keyStatus >= 0.5 )
	elseif actionName == "vcaShifterLH" and self.vehicle.vcaShifterIndex > 0 then 
		self.vehicle:vcaSetState( "vcaShifterLH", not self.vehicle.vcaShifterLH )
		if not self.vehicle.vcaNeutral then 
			self:gearShifter( self.vehicle.vcaShifterIndex, keyStatus >= 0.5 )
		end 
	end 
end 

vehicleControlAddonTransmissionIVT = {}
function vehicleControlAddonTransmissionIVT:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmissionIVT,vehicleControlAddonTransmissionBase), "IVT", 1, 0, {}, 0 )
	return self 
end 

vehicleControlAddonTransmission4x4 = {}
function vehicleControlAddonTransmission4x4:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmission4x4,vehicleControlAddonTransmissionBase), "4X4", 4, 750, {2,1,1}, 1000 )
	return self 
end 

vehicleControlAddonTransmission4PS = {}
function vehicleControlAddonTransmission4PS:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmission4PS,vehicleControlAddonTransmissionBase), "4PS", 4, 0, {2,1,1}, 750 )
	return self 
end 

vehicleControlAddonTransmission2x6 = {}
function vehicleControlAddonTransmission2x6:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmission2x6,vehicleControlAddonTransmissionBase), "2X6", 6, 750, {0}, 1000 )
	return self 
end 
function vehicleControlAddonTransmission2x6:splitGearsForShifter()
	return false 
end 

vehicleControlAddonTransmissionFPS = {}
function vehicleControlAddonTransmissionFPS:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmissionFPS,vehicleControlAddonTransmissionBase), "FPS", 12, 0, {}, 0 )
	return self 
end 

vehicleControlAddonTransmission6PS = {}
function vehicleControlAddonTransmission6PS:new()
	local self = vehicleControlAddonTransmissionBase:new( vcaClass(vehicleControlAddonTransmission6PS,vehicleControlAddonTransmissionBase), "6PS", 2, 0, {0,0,0,0,0}, 750 )
	return self 
end 

