local centerX = display.contentCenterX
local centerY = display.contentCenterY
local _W = display.contentWidth
local _H = display.contentHeight

local physics = require("physics")

physics.start()

physics.setScale( 60 ) 
physics.setGravity( 0, 0 ) -- Vista superior, por lo tanto, sin gravedad
display.setStatusBar( display.HiddenStatusBar )

-- Constantes
local spriteTime = 100 -- Tiempo de iteración del sprite
local animationStop = 2.8 -- La animación del sprite se detiene por debajo de esta velocidad
local screenW, screenH = _W, _H
local viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight -- Propiedades del tamaño visible de la pantalla
local ballBody = { density=0.8, friction=1.0, bounce=.7, radius=15 }

-- Inicializa el escenario del juego
function init()
	
	stageGroup = display.newGroup()
	
	-- Se crea el rectángulo de la mesa de billar
	local tableRectangle = display.newRect(384,512, 484, 912)
	tableRectangle.fill = { 0, 1, 0.1 } -- Color de la mesa (verde)
	stageGroup:insert(tableRectangle)

	local endBumperShape = { -212,-18, 212,-18, 190,2, -190,2 }
	local sideBumperShape = { -18,-207, 2,-185, 2,185, -18,207 }
	local bumperBody = { friction=0.5, bounce=0.5, shape=endBumperShape }

	-- Configura los topes (bumpers) en los extremos
	local bumper1 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper1)
	physics.addBody( bumper1, "static", bumperBody )
	bumper1.x = 380; bumper1.y = 58

	local bumper2 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper2)
	physics.addBody( bumper2, "static", bumperBody )
	bumper2.x = 380; bumper2.y = 966; bumper2.rotation = 180

	-- Anula la forma anterior, pero reutiliza las otras propiedades del cuerpo
	bumperBody.shape = sideBumperShape

	-- Configura los topes (bumpers) laterales
	local bumper3 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper3)
	bumper3.x = 157; bumper3.y = 279
	physics.addBody( bumper3, "static", bumperBody )

    local bumper5 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper5)
	physics.addBody( bumper5, "static", bumperBody )
	bumper5.x = 157; bumper5.y = 745

	local bumper4 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper4)
	bumper4.x = 611; bumper4.y = 279; bumper4.rotation = 180
	physics.addBody( bumper4, "static", bumperBody)

	local bumper6 = display.newRect(0, 0, 0, 0)
	stageGroup:insert(bumper6)
	physics.addBody( bumper6, "static", bumperBody )
	bumper6.x = 611; bumper6.y = 545; bumper6.rotation = 180
	
	-- Llama a la función para configurar las bolas
	ballProperties()
end

-- Configura todas las propiedades y funciones de las bolas de billar
function ballProperties()
	
	-- Crea un grupo para las bolas de juego
	gameBallGroup = display.newGroup() 
	
	local v = 0
	local reqForce = .18
	local maxBallSounds = 4
	
	-- Crea la bola blanca
	local cueballCircle = display.newCircle( 100, 100, 10 )
	cueballCircle:setFillColor( 1 ) -- Color blanco
	cueball = cueballCircle
	gameBallGroup:insert(cueball)
	cueball.x = centerX; cueball.y = 780
	physics.addBody( cueball, ballBody )
	cueball.linearDamping = 0.3 -- Amortiguación lineal para simular fricción
	cueball.angularDamping = 0.8 -- Amortiguación angular para detener el giro
	cueball.isBullet = true -- Detección continua de colisiones
	cueball.type = "cueBall"
	cueball.collision = onCollision
	cueball:addEventListener("collision", cueball) -- Inicia la animación al colisionar
	cueball:addEventListener( "postCollision", cueball )
	
	-- Crea el objetivo giratorio
	target = display.newCircle( 100, 100, 20 )
	target.x = cueball.x; target.y = cueball.y; target.alpha = 0

	-- Configura las propiedades y crea las bolas de colores
	local spriteInstance = {}
	local n = 1
	for i = 1, 5 do
			for j = 1, (6-i) do 
				local ball = display.newCircle( 100, 100, 10 )
				ball:setFillColor( math.random(), math.random(), math.random() ) -- Color aleatorio
				spriteInstance[n] = ball
				gameBallGroup:insert(spriteInstance[n])
				physics.addBody(spriteInstance[n], ballBody)
				spriteInstance[n].x = 279 + (j*34) + (i*15) 
				spriteInstance[n].y = 185 + (i*27)
				spriteInstance[n].linearDamping = 0.3 -- Simula la fricción del fieltro
				spriteInstance[n].angularDamping = 2 -- Detiene el giro continuo
				spriteInstance[n].isBullet = true -- Detección continua de colisiones
				spriteInstance[n].active = true -- La bola está activa
				spriteInstance[n].bullet = false -- Detección continua de colisiones
				spriteInstance[n].id = "spriteBall"
				spriteInstance[n]:addEventListener( "postCollision", spriteInstance[n] )
				n = n + 1
			end
	end
	
	-- Añade el listener para disparar la bola blanca
	cueball:addEventListener( "touch", cueShot ) 
	
end

-- Dispara la bola blanca usando un vector de fuerza visible
function cueShot( event )

	local t = event.target
	local phase = event.phase
	
	if "began" == phase then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		
		-- Detiene el movimiento actual de la bola blanca
		t:setLinearVelocity( 0, 0 )
		t.angularVelocity = 0

		-- Posiciona el objetivo en la bola blanca
		target.x = t.x
		target.y = t.y

		-- Inicia la rotación del objetivo
		startRotation = function()
			target.rotation = target.rotation + 4
		end
		
		Runtime:addEventListener( "enterFrame", startRotation )
		
		-- Muestra el objetivo con una transición
		local showTarget = transition.to( target, { alpha=0.4, xScale=0.4, yScale=0.4, time=200 } )
		myLine = nil

	elseif t.isFocus then
		
		if "moved" == phase then
			-- Borra la línea anterior si existe
			if ( myLine ) then
				myLine.parent:remove( myLine )
			end
			-- Dibuja una nueva línea desde la bola blanca hasta el punto de toque
			myLine = display.newLine( t.x,t.y, event.x,event.y )
			myLine:setStrokeColor( 1, 1, 1, 50/255 )
			myLine.strokeWidth = 15

		elseif "ended" == phase or "cancelled" == phase then
		
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			
			-- Detiene la rotación del objetivo
			local stopRotation = function()
				Runtime:removeEventListener( "enterFrame", startRotation )
			end
			
			-- Oculta el objetivo con una transición
			local hideTarget = transition.to( target, { alpha=0, xScale=1.0, yScale=1.0, time=200, onComplete=stopRotation } )
			
			-- Borra la línea de fuerza si existe
			if ( myLine ) then
				myLine.parent:remove( myLine )
			end
			
			-- Aplica la fuerza a la bola blanca para dispararla
			t:applyForce( (t.x - event.x), (t.y - event.y), t.x, t.y )	
		end
	end

	return true -- Detiene la propagación del evento táctil
end

init()