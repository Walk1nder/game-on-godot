extends Node

func _ready():
	test_level_transition()

func test_level_transition():
	var lvr = $"../objects/lever"
	lvr.activate_lever()
	if lvr.activated:
		print("Object interact test passed")
	else:
		print("Object interact test failed")
