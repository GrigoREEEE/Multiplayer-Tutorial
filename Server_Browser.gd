extends Control
signal found_sever(ip,port,room_info)
signal update_sever(ip,port,room_info)
signal join_game(ip)

var broadcast_timer : Timer
var broadcaster : PacketPeerUDP
var listener : PacketPeerUDP

@export var server_info : PackedScene

var room_info : Dictionary = {"name": "name", "player_count": 0}
@export var listen_port = 1234
@export var broadcast_port = 2345
@export var broadcast_adress : String
# Called when the node enters the scene tree for the first time.
func reverse_string(s):
	var r := ""
	for i in range(s.length()-1, -1, -1):
		r += s[i]
	var pos = r.find(".",0)
	s = s.substr(0,(s.length()-pos))
	print(s)
	return s

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			broadcast_adress =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	elif OS.has_feature("x11"):
		if OS.has_environment("HOSTNAME"):
			broadcast_adress =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			broadcast_adress =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	broadcast_timer = $broadcast_timer
	broadcast_adress = reverse_string(str(broadcast_adress)) + "255"
	print("Broadcast Adress is " + broadcast_adress)
	setup()

func set_up_broadcast(name):
	room_info.name = name
	room_info.player_count = GameManager.players.size()
	
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcast_adress, listen_port)
	
	var ok = broadcaster.bind(broadcast_port)
	
	if ok == OK:
		print("Bound to Broadcast Port " + str(broadcast_port) + " Successful!")
		$Indicator.text = "Bound to listening port: true"
	else:
		print("Fail to bound to Broadcast Port!")
		$Indicator.text = "Bound to listening port: false"
	broadcast_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if listener.get_available_packet_count() > 0:
		var server_ip = listener.get_packet_ip()
		var server_port = listener.get_packet_port()
		var bytes = listener.get_packet()
		var data = bytes.get_string_from_ascii()
		var room_info = JSON.parse_string(data)
		print("Server IP: " + str(server_ip) + "\n Server IP: " + str(server_port) + "\n Room Info:" + str(room_info))
		
		for i in $Panel/Server_Container.get_children():
			if i.name == room_info.name:
				i.get_node("IP").text = server_ip
				i.get_node("Player_Count").text = str(room_info.player_count)
				update_sever.emit(server_ip,server_port,room_info)
				return

		var current_info = server_info.instantiate()
		current_info.name  = room_info.name
		current_info.get_node("Name").text = room_info.name
		current_info.get_node("IP").text = server_ip
		current_info.get_node("Player_Count").text = str(room_info.player_count)
		$Panel/Server_Container.add_child(current_info)
		current_info.join_game.connect(join_by_ip)
		found_sever.emit(server_ip,server_port,room_info)
			

func _on_broadcast_timer_timeout():
	print("Broadcasting Game!")
	room_info.player_count = GameManager.players.size()
	var data = JSON.stringify(room_info)
	var packet = data.to_ascii_buffer()
	broadcaster.put_packet(packet)
	
	pass # Replace with function body.

func cleanup():
	listener.clsoe()
	broadcast_timer.stop()
	if broadcaster != null:
		broadcaster.close()
		
func setup():
	listener = PacketPeerUDP.new()
	var ok = listener.bind(listen_port)
	if ok == OK:
		print("Bound to Listen Port " + str(listen_port) + " Successful!")
	else:
		print("Fail to bound to Listen Port!")

func exit_tree():
	cleanup()
	
func join_by_ip(ip):
	join_game.emit(ip)
