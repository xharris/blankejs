Bezier = Class{
	init = function(self, ...)
		self._bezier = love.math.newBezierCurve()
		self:addPoints(...)
		self.persistent = true
		_addGameObject('bezier', self)
	end,

	addPoints = function(self, ...)
		local points = {...}
		for p = 1,#points,2 do
			self:addPoint(points[p], points[p+1])
		end
	end,

	addPoint = function(self, x, y, i)
		self._bezier:insertControlPoint(x,y,ifndef(i,-1))
		return self
	end,

	removePoint = function(self, i)
		self._bezier:removeControlPoint(i)
		return self
	end,

	getPoint = function(self, i)
		return self._bezier:getControlPoint(i)
	end,

	size = function(self)
		return self._bezier:getControlPointCount()
	end,

	clear = function(self)
		while self:size() > 0 do
			self:removePoint(1)
		end
	end,

	-- between 0 and 1
	at = function(self, t)
		return self._bezier:evaluate(t)
	end,

	draw = function(self)
		if self:size() > 1 then	
			Draw.line(self._bezier:render())
		end
	end,

	drawPoints = function(self)
		for i = 1, self:size() do
			local x, y = self:getPoint(i)
			Draw.point(x,y)
		end
	end
}

return Bezier