## Dev helper: when the game is started with `-- --shot=<path> [--frames=N]`, it saves a
## screenshot of the main viewport after N frames and quits. Used to review art from the CLI.
class_name Shot
extends RefCounted

static func arg(name: String, default := "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
		if a == "--" + name:
			return "1"
	return default

static func maybe_capture(tree: SceneTree, default_frames := 30) -> void:
	var path := arg("shot")
	if path == "":
		return
	var frames := int(arg("frames", str(default_frames)))
	for i in frames:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT saved ", path, " ", img.get_size())
	tree.quit()
