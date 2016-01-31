
def log event

	if !$logs[$phase] then $logs[$phase] = [] end
	$logs[$phase].push(event)

end

def playersAlive

	alive = 0
	$players.each do |player|
		if player.isAlive == 1 then alive += 1 end
	end

end


# Create Players

# Make Player1
code = "
case attack.back
  turn.right
case default
  idle
"
p1 = Blindfolk.new(1,0,1,code)

# Make Player3
code = "
case attack.forward
  attack.forward
case collide.forward
  step.right
  step.right
case default
  attack.forward
"
p3 = Blindfolk.new(3,0,0,code)

$players = [p1,p3].shuffle

$logs = {}

# Play

$phase = 1
while $phase <= 10
	for player in $players
		player.act()
	end
	if playersAlive == 1 then break end
	$phase += 1
end

# Print Logs

$logs.each do |phase,events|
	if events.length == 0 then next end
	puts "==================="
	puts "= Phase: #{phase}"
	puts "==================="
	events.each do |event|
		puts "+ #{event}"
	end
end


