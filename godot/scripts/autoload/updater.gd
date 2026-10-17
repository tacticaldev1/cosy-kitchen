## Updater: checks GitHub Releases for a newer version and, on Windows, replaces the running
## exe with the new one in place (rename the running exe → download → restart).
## The repo is set in Project Settings: application/config/github_repo ("owner/name").
extends Node

signal status_changed

const ASSET := "Cosy-Kitchen.exe"
var repo := ""
var current := "0.0.0"
var latest := ""
var download_url := ""
var page_url := ""
var state := "idle"     # idle | checking | uptodate | available | downloading | failed | offline
var progress := 0.0
var _http: HTTPRequest
var _dl: HTTPRequest

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	repo = str(ProjectSettings.get_setting("application/config/github_repo", ""))
	current = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	_cleanup_old()
	if can_check() and Shot.arg("dev") == "" and Shot.arg("shot") == "" and not OS.get_cmdline_user_args().has("--test"):
		check.call_deferred()

func can_check() -> bool:
	return repo != "" and not OS.has_feature("web")

## In-place updating only works for the exported Windows build.
func can_self_update() -> bool:
	return OS.has_feature("template") and OS.get_name() == "Windows"

func releases_page() -> String:
	return "https://github.com/%s/releases/latest" % repo

func check() -> void:
	if not can_check() or state == "checking" or state == "downloading": return
	state = "checking"
	status_changed.emit()
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 12.0
		add_child(_http)
		_http.request_completed.connect(_on_checked)
	var err := _http.request("https://api.github.com/repos/%s/releases/latest" % repo, ["Accept: application/vnd.github+json", "User-Agent: CosyKitchen"])
	if err != OK:
		state = "offline"
		status_changed.emit()

func _on_checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		state = "offline"
		status_changed.emit()
		return
	var d = JSON.parse_string(body.get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY:
		state = "failed"
		status_changed.emit()
		return
	latest = str(d.get("tag_name", "")).trim_prefix("v")
	page_url = str(d.get("html_url", releases_page()))
	download_url = ""
	for a in d.get("assets", []):
		if str(a.get("name", "")) == ASSET:
			download_url = str(a.get("browser_download_url", ""))
	state = "available" if newer(latest, current) else "uptodate"
	status_changed.emit()

static func newer(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y: return x > y
	return false

## Downloads the new exe next to the running one, swaps them and restarts.
func update_now() -> void:
	if state != "available": return
	if not can_self_update() or download_url == "":
		OS.shell_open(page_url if page_url != "" else releases_page())
		return
	var exe := OS.get_executable_path()
	var tmp := exe.get_base_dir().path_join("Cosy-Kitchen.download")
	state = "downloading"
	progress = 0.0
	status_changed.emit()
	if _dl == null:
		_dl = HTTPRequest.new()
		_dl.max_redirects = 10
		_dl.timeout = 600.0
		_dl.use_threads = true
		add_child(_dl)
	_dl.download_file = tmp
	_dl.request_completed.connect(func(result: int, code: int, _h, _b): _on_downloaded(result, code, exe, tmp), CONNECT_ONE_SHOT)
	if _dl.request(download_url, ["User-Agent: CosyKitchen"]) != OK:
		_fail("Couldn't start the download.")

func _process(_dt: float) -> void:
	if state == "downloading" and _dl:
		var total := _dl.get_body_size()
		if total > 0:
			progress = float(_dl.get_downloaded_bytes()) / total
			status_changed.emit()

func _on_downloaded(result: int, code: int, exe: String, tmp: String) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200 or FileAccess.get_file_as_bytes(tmp).size() < 1000000:
		DirAccess.remove_absolute(tmp)
		_fail("The download didn't finish. Try again later.")
		return
	var old := exe.get_basename() + ".old"
	DirAccess.remove_absolute(old)
	# Windows lets a running exe be renamed (not overwritten), so move it aside first.
	if DirAccess.rename_absolute(exe, old) != OK:
		DirAccess.remove_absolute(tmp)
		_fail("This folder is read-only, so the update opens in your browser instead.")
		OS.shell_open(page_url)
		return
	if DirAccess.rename_absolute(tmp, exe) != OK:
		DirAccess.rename_absolute(old, exe)
		_fail("Couldn't install the update.")
		return
	Save.save()
	OS.create_process(exe, [])
	get_tree().quit()

func _fail(msg: String) -> void:
	state = "failed"
	status_changed.emit()
	if Game.I and Game.I.hud: Game.I.hud.toast(msg)

func _cleanup_old() -> void:
	if not OS.has_feature("template"): return
	var old := OS.get_executable_path().get_basename() + ".old"
	if FileAccess.file_exists(old):
		DirAccess.remove_absolute(old)
