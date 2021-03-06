class Blindfolk

	def initialize id,script,book

		@id = id
		@rules = parse(script)
		@book = book
		@stamina = 11
		@actionIndex = 0
		@status = "default"
		@isAlive = 1
		@score = 0

		@orientation = 0
		@x = 0
		@y = 0
		@name = "<blindfolk>#{@id}</blindfolk>"

	end

	# Accessors

	def id
		return @id
	end

	def x
		return @x
	end

	def y
		return @y
	end

	def name
		return @name
	end

	def isAlive
		return @isAlive.to_i
	end

	def score
		return @score
	end

	def book
		return @book
	end

	# Parser

	def parse code

		rules = {}
		code = code.gsub("\n\n","\n")
		_case = "default"
		code.lines.each do |line|
			line = line.strip
			if line == "" then next end
			if line[0,5] == "case " then _case = line.sub("case ","") ; next end
			if !rules[_case] then rules[_case] = [] end
			rules[_case].push(line)
		end
		return rules

	end

	# Actions

	def act

		@stamina -= 1

		if @stamina < 1 then return end
		if @isAlive == 0 then return end

		if !@rules[@status] then @rules[@status] = ["idle"] end

		actionIndexClamped = @actionIndex % @rules[@status].length
		command = @rules[@status][actionIndexClamped]

		if command.include?("move.") then act_move(command)
		elsif command.include?("turn.") then act_turn(command)
		elsif command.include?("step.") then act_step(command)
		elsif command.include?("attack.") then act_attack(command)
		elsif command.include?("say ") then act_say(command)
		elsif command.include?("taunt ") then act_taunt(command)
		elsif command.include?("mark ") then act_mark(command)
		else act_idle end

		@actionIndex += 1

	end

	def act_move command

		method = command.sub("move.","")
		new_x = @x
		new_y = @y

		if method == "forward"
			if @orientation == 0 then new_y += 1 end
			if @orientation == 1 then new_x += 1 end
			if @orientation == 2 then new_y -= 1 end
			if @orientation == 3 then new_x -= 1 end
		elsif method == "backward"
			if @orientation == 0 then new_y -= 1 end
			if @orientation == 1 then new_x -= 1 end
			if @orientation == 2 then new_y += 1 end
			if @orientation == 3 then new_x += 1 end
		elsif method == "random"
			random = rand() * 4
			if random == 0 then new_y -= 1 end
			if random == 1 then new_x -= 1 end
			if random == 2 then new_y += 1 end
			if random == 3 then new_x += 1 end
		else
			log("Phase #{$phase}","#{@name} slips and falls, move.#{method} is invalid.", @stamina)
			return
		end

		if enemyAtLocation(new_x,new_y)
			log("Phase #{$phase}","#{@name} attemps to move, but is blocked by #{enemyAtLocation(new_x,new_y).name}.", @stamina)
			collide(enemyAtLocation(new_x,new_y)) 
		else 
			@x = new_x ; @y = new_y 
			log("Phase #{$phase}","#{@name} moved to #{@x},#{@y}.", @stamina)
		end

	end

	def act_step command

		method = command.sub("step.","")
		new_x = @x
		new_y = @y

		if method == "left"
			if @orientation == 0 then new_x -= 1 end
			if @orientation == 1 then new_y += 1 end
			if @orientation == 2 then new_x += 1 end
			if @orientation == 3 then new_y -= 1 end
		elsif method == "right"
			if @orientation == 0 then new_x += 1 end
			if @orientation == 1 then new_y -= 1 end
			if @orientation == 2 then new_x -= 1 end
			if @orientation == 3 then new_y += 1 end
		else
			log("Phase #{$phase}","#{@name} slips and falls, step.#{method} is invalid.", @stamina)
			return
		end

		if enemyAtLocation(new_x,new_y)
			log("Phase #{$phase}","#{@name} attemps to step, but is blocked by #{enemyAtLocation(new_x,new_y).name}.", @stamina)
			collide(enemyAtLocation(new_x,new_y)) 
		else 
			@x = new_x ; @y = new_y 
			log("Phase #{$phase}","#{@name} moved to #{@x},#{@y}.", @stamina)
		end

	end

	def act_attack command

		method = command.sub("attack.","")
		new_x = @x
		new_y = @y

		if method == "forward"
			if @orientation == 0 then new_y += 1 end
			if @orientation == 1 then new_x += 1 end
			if @orientation == 2 then new_y -= 1 end
			if @orientation == 3 then new_x -= 1 end
		elsif method == "backward"
			if @orientation == 0 then new_y -= 1 end
			if @orientation == 1 then new_x -= 1 end
			if @orientation == 2 then new_y += 1 end
			if @orientation == 3 then new_x += 1 end
		else
			log("Phase #{$phase}","#{@name} fails their attack.", @stamina)
			return
		end

		target = enemyAtLocation(new_x,new_y)

		if target
			if target.book == book && book.length > 3
				log("Phase #{$phase}","#{@name} rallies #{target.name}.", @stamina)
				target.charge()
			else
				log("Phase #{$phase}","#{@name} attacks #{target.name}.", @stamina)
				target.attacked(self) 
			end
		else 
			log("Phase #{$phase}","#{@name} attacks nothing #{method} at #{new_x},#{new_y} from #{@x},#{@y}.", @stamina)
		end

		# Land blow after the riposte

		if target && target.x == new_x && target.y == new_y
			if @stamina > 0 && target.isAlive == 1 && target.book != book
				kill(target)
			end
		end

	end

	def act_turn command

		method = command.sub("turn.","")

		if method == "right"
			@orientation = (@orientation + 1) & 3
		end

		if method == "left"
			@orientation = (@orientation - 1) & 3
		end

		log("Phase #{$phase}","#{@name} turns #{method}.", @stamina)

	end

	def act_say command

		value = command.sub("say ","")
		log("Phase #{$phase}","#{@name} says \"#{value}\".", @stamina)

	end

	def act_taunt command

		value = command.sub("taunt ","")
		log("Phase #{$phase}","#{@name} #{value}.", @stamina)

	end

	def act_mark command

		value = command.sub("mark ","")
		@book = value
		log("Phase #{$phase}","#{@name} enters the book of <book>#{value}</book>.", @stamina)

	end

	def act_idle

		log("Phase #{$phase}","#{@name} idles.", @stamina)

	end

	# Ripostes

	def collide enemy

		log("Phase #{$phase}","#{@name} collides with #{enemy.name}.", @stamina)

		caseOrientation = ""

		# North
		if enemy.x == @x && enemy.y == @y + 1
			if @orientation == 0 then caseOrientation = "forward" end
			if @orientation == 1 then caseOrientation = "left" end
			if @orientation == 2 then caseOrientation = "backward" end
			if @orientation == 3 then caseOrientation = "right" end
		end

		# East
		if enemy.x == @x + 1 && enemy.y == @y
			if @orientation == 0 then caseOrientation = "right" end
			if @orientation == 1 then caseOrientation = "forward" end
			if @orientation == 2 then caseOrientation = "left" end
			if @orientation == 3 then caseOrientation = "backward" end
		end

		# South
		if enemy.x == @x && enemy.y == @y - 1
			if @orientation == 0 then caseOrientation = "backward" end
			if @orientation == 1 then caseOrientation = "right" end
			if @orientation == 2 then caseOrientation = "forward" end
			if @orientation == 3 then caseOrientation = "left" end
		end

		# West
		if enemy.x == @x - 1 && enemy.y == @y
			if @orientation == 0 then caseOrientation = "left" end
			if @orientation == 1 then caseOrientation = "backward" end
			if @orientation == 2 then caseOrientation = "right" end
			if @orientation == 3 then caseOrientation = "forward" end
		end

		# Riposte

		if @rules["collide.#{caseOrientation}"]
			log("Phase #{$phase}","#{@name} counters!", @stamina)
			@status = "collide.#{caseOrientation}"
			@actionIndex = 0
			for riposte in @rules["collide.#{caseOrientation}"]
				self.act()
			end
			@status = "default"
			@actionIndex = 0
		elsif @rules["collide"]
			log("Phase #{$phase}","#{@name} counters!", @stamina)
			@status = "collide"
			@actionIndex = 0
			for riposte in @rules["collide"]
				self.act()
			end
			@status = "default"
			@actionIndex = 0
		end

	end

	def attacked enemy

		caseOrientation = ""

		if @orientation == 0
			if enemy.x == @x && enemy.y == @y + 1 then caseOrientation = "forward" end
			if enemy.x == @x && enemy.y == @y - 1 then caseOrientation = "backward" end
		end
		if @orientation == 1
			if enemy.x == @x + 1 && enemy.y == @y then caseOrientation = "forward" end
			if enemy.x == @x - 1 && enemy.y == @y then caseOrientation = "backward" end
		end
		if @orientation == 2
			if enemy.x == @x && enemy.y == @y - 1 then caseOrientation = "forward" end
			if enemy.x == @x && enemy.y == @y + 1 then caseOrientation = "backward" end
		end
		if @orientation == 3
			if enemy.x == @x - 1 && enemy.y == @y then caseOrientation = "forward" end
			if enemy.x == @x + 1 && enemy.y == @y then caseOrientation = "backward" end
		end

		# Riposte
		if @rules["attack.#{caseOrientation}"]
			log("Phase #{$phase}","#{@name} counters!", @stamina)
			@status = "attack.#{caseOrientation}"
			@actionIndex = 0
			for riposte in @rules["attack.#{caseOrientation}"]
				self.act()
			end
			@status = "default"
			@actionIndex = 0
		elsif @rules["attack"]
			log("Phase #{$phase}","#{@name} counters!", @stamina)
			@status = "attack"
			@actionIndex = 0
			for riposte in @rules["attack"]
				self.act()
			end
			@status = "default"
			@actionIndex = 0		
		end

	end

	# Events

	def kill enemy

		log("Phase #{$phase}","#{@name} kills #{enemy.name}.", @stamina)
		@score += 1
		enemy.die()

		# Trigger the kill case
		if @rules["kill"]
			@status = "kill"
			@actionIndex = 0
			for riposte in @rules["kill"]
				self.act()
			end
			@status = "default"
			@actionIndex = 0
		end

	end

	def die

		@isAlive = 0

	end

	def charge

		@stamina += 1
		log("Phase #{$phase}","#{@name} gains +1 stamina!", @stamina)

	end

	# Tools

	def enemyAtLocation x,y

		for player in $players
			if player.id == @id then next end
			if player.isAlive == 0 then next end
			if player.x == x && player.y == y then return player end
		end

		return nil

	end

end