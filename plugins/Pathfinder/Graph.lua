local Graph = Class{
	init = function(self)
		self.vertices = {}
		self.edges = {}
	end,

	setVertex = function(self, id, value)
		self.vertices[id] = value
	end,

	setEdge = function(self, from, to, value)
		if not self.edges[from] then self.edges[from] = {} end
		if not self.edges[to] then self.edges[to] = {} end

		self.edges[from][to] = value
		self.edges[to][from] = value
	end, 

	removeVertex = function(self, id)
		if not self.edges[id] then return end

		for other_id, value in pairs(self.edges[id]) do
			self.edges[other_id][id] = nil
		end
		self.edges[id] = {}
	end
}

return Graph