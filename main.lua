local types = require("types")
local complex = types.complex
local vec2 = types.vec2

local tau = math.pi * 2

local gravityStrength = complex(10, 0)
local imaginaryColourScale = 150

local dtMultiplierLinearTime = complex(1, 0)
local circularTimeRealSecondsForFullCycle = 10
local circularTimeSpeed = 1
local useCircularTime = false

local timeReal
local particles

function love.load()
	particles = {}
	for i = 1, 50 do
		particles[i] = {
			position = vec2(
				complex(
					love.math.random() * 200 - 50,
					love.math.random() * 20 - 5
				),
				complex(
					love.math.random() * 200 - 50,
					love.math.random() * 20 - 5
				)
			),
			velocity = vec2(
				complex(
					love.math.random() * 20 - 10,
					love.math.random() * 2 - 1
				),
				complex(
					love.math.random() * 20 - 10,
					love.math.random() * 2 - 1
				)
			),
			mass = complex(love.math.random() * 8 + 2, love.math.random() * 2 + 1)
		}
		particles[i].radius = complex.abs(particles[i].mass).re / 2
	end

	timeReal = 0
end

function love.update(dt)
	local dtMultiplier = useCircularTime and complex(
		circularTimeSpeed * math.cos(tau * timeReal / circularTimeRealSecondsForFullCycle),
		circularTimeSpeed * math.sin(tau * timeReal / circularTimeRealSecondsForFullCycle)
	) or dtMultiplierLinearTime

	for i = 1, #particles - 1 do
		local particleA = particles[i]
		for j = i + 1, #particles do
			local particleB = particles[j]

			local difference = particleB.position - particleA.position
			local distance = #difference
			local direction = difference / distance

			-- local distanceFactor = math.min(1, 1 / (distance * distance).re)
			local distanceFactor = math.min(1, 1 / distance.re)
			local force = gravityStrength * particleA.mass * particleB.mass * distanceFactor

			particleA.velocity = particleA.velocity + direction * force * dt * dtMultiplier / particleA.mass
			particleB.velocity = particleB.velocity - direction * force * dt * dtMultiplier / particleB.mass
		end
	end
	for i = 1, #particles do
		local particle = particles[i]
		particle.position = particle.position + particle.velocity * dt * dtMultiplier
	end

	timeReal = timeReal + dt
end

function love.draw()
	local w, h = love.graphics.getDimensions()

	love.graphics.translate(w / 2, h / 2)

	for i = 1, #particles do
		local particle = particles[i]

		-- Different approaches to drawing

		love.graphics.setColor(0.5, particle.position.x.im / imaginaryColourScale + 0.5, particle.position.y.im / imaginaryColourScale + 0.5)
		love.graphics.circle("fill", particle.position.x.re, particle.position.y.re, particle.radius)

		-- love.graphics.setColor(0.5, particle.position.y.re / imaginaryColourScale + 0.5, particle.position.y.im / imaginaryColourScale + 0.5)
		-- love.graphics.circle("fill", particle.position.x.re, particle.position.x.im, particle.radius)

		-- love.graphics.setColor(0.5, particle.position.y.re / imaginaryColourScale + 0.5, particle.position.x.im / imaginaryColourScale + 0.5)
		-- love.graphics.circle("fill", particle.position.x.re, particle.position.y.im, particle.radius)
	end
	love.graphics.setColor(1, 1, 1)
end

-- sqrt demonstration
-- function love.draw()
-- 	local w, h = love.graphics.getDimensions()
-- 	local scale = 75

-- 	love.graphics.setBlendMode("add")

-- 	love.graphics.translate(w / 2, h / 2)
-- 	love.graphics.scale(1, -1)

-- 	love.graphics.scale(scale)
-- 	love.graphics.setLineWidth(1 / scale)

-- 	local mx, my = love.mouse.getPosition()
-- 	local x, y = (mx - w / 2) / scale, -(my - h / 2) / scale
-- 	if love.keyboard.isDown("lshift") then
-- 		y = 0
-- 	end
-- 	local a = complex(x, y)
-- 	local b = complex.sqrt(a)
-- 	local c = b * b

-- 	love.graphics.setPointSize(8)
-- 	love.graphics.setColor(1, 0, 0)
-- 	love.graphics.points(a.re, a.im)
-- 	love.graphics.setColor(0, 1, 0)
-- 	love.graphics.points(b.re, b.im)
-- 	love.graphics.setColor(0, 0, 1)
-- 	love.graphics.points(c.re, c.im)

-- 	love.graphics.setPointSize(5)
-- 	love.graphics.setColor(0.5, 0.5, 0.5)
-- 	love.graphics.points(1, 0) -- 1
-- 	love.graphics.points(0, 1) -- i
-- 	love.graphics.points(-1, 0) -- -1
-- 	love.graphics.points(0, -1) -- -i
-- 	love.graphics.circle("line", 0, 0, 1)
-- 	love.graphics.line(0, -h / 2, 0, h / 2)
-- 	love.graphics.line(-w / 2, 0, w / 2, 0)
-- end
