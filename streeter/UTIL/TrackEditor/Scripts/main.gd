extends Control

# File dialogs
var fd_open: FileDialog
var fd_save: FileDialog
var fd_export: FileDialog
var fd_map: FileDialog

# track layout
@onready var status_label : Label = $HBoxContainer/TrackLayoutVBoxContainer/toolbar/status_label
@onready var spin_curve : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/toolbar/spin_curve
@onready var spin_length : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/toolbar/spin_length
@onready var spin_zoom : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/toolbar/spin_zoom


@onready var track_name : Label = $HBoxContainer/TrackLayoutVBoxContainer/lbl_track_name

# Appearance
const GRID := 32
const GRID_MINOR_COLOR := Color(0.23, 0.23, 0.23)
const GRID_MAJOR_COLOR := Color(0.35, 0.35, 0.35)
const SEG_COLOR := Color(0.82, 0.82, 0.82)
const SEG_SELECTED_COLOR := Color(0.0, 0.82, 0.66)
const SEG_HOVER_COLOR := Color(1,1,1)
const POINT_COLOR := Color(0.56,0.56,0.56)

# hover state
var hover_index := -1

# selection threshold in pixels
const PICK_TOLERANCE := 8.0

const NEAR_ZERO:= 0.00001

# Add mode
var add_mode := false
var add_start: Vector2
var total_road_length : float = 0.0


class ScrollValues:
	var row_start: int
	var h_scroll_vals: PackedInt32Array

	func _init(_start := 64):
		row_start = _start
		h_scroll_vals = PackedInt32Array()
		



class Segment:
	var p1: Vector2
	var p2: Vector2
	var curve: float
	var length: float
	var radius: float
	var center: Vector2         # degrees (radian make me brain no worky )
	var arc_start_angle: float  # degrees
	
	func to_dict() -> Dictionary:
		var dict : Dictionary = {}
		dict["p1"] = p1
		dict["p2"] = p2
		dict["curve"] = curve
		dict["length"] = length
		dict["radius"] = radius
		dict["center"] = center
		dict["arc_start_angle"] = arc_start_angle
		
		return dict
	func write_out() -> void:
		print("-------------------")
		print("p1: %s p2: %s len: %f" % [p1, p2, length])
		print("curve: %f radius: %f arc_start_angle: %f center: %s" % [curve, radius, arc_start_angle, center])
	
	func _init(_p1 := Vector2.ZERO, _p2 := Vector2.ZERO, _curve := 0.0):
		print("CONSTRUCT p1: %s p2: %s" %[_p1,_p2])
		p1 = _p1; 
		p2 = _p2; 
		length = ( p2 - p1 ).length();
		curve = _curve
		radius = -1.0
		center = Vector2.INF
		arc_start_angle = 0.0
 



	func from_dict(dict : Dictionary) -> void:
		p1 = string_to_vector( dict["p1"] )
		p2 = string_to_vector( dict["p2"] )
		
		curve = float ( dict["curve"])
		length = float ( dict["length"])
		radius = float ( dict["radius"])
		center = string_to_vector( dict["center"] )
		arc_start_angle = float ( dict["arc_start_angle"])
 
	
		
		
	func string_to_vector(st : String) -> Vector2:
		var vec : Vector2 = Vector2.INF 
		st = st.substr( 1, st.length() - 2 )
		var parts = st.split(",", true, 1 )
		if parts.size() != 2:
			return vec 
		
		vec = Vector2 (  float( parts[0]) if parts[0].dedent().is_valid_float() else INF,  float( parts[1]) if parts[1].dedent().is_valid_float() else INF )
		return vec
		
		
		
		
var segments: Array[Segment] = []
var background_points: Array[Vector2] = []

var selected_index := -1

static var track_zoom: float
static var track_offset: Vector2 = Vector2( 600, 400 )
static var track_dragging : bool = false
static var track_drag_last_pt : Vector2
var track_point: Vector2 = Vector2.INF


var _updating_control: bool = false

# raster road 
@onready var screen_width_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/lin_ed_screen_width
@onready var scroll_width_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/lin_ed_scroll_width
@onready var screen_height_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/lin_ed_screen_height
@onready var z_map_length_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/lin_ed_zmap_length
@onready var y_world_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/lin_ed_y_world
@onready var curve_dx_scale_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_curve_dx_scale
@onready var curve_bgdx_scale_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_curve_bgdx_scale
@onready var player_bottom_y_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_player_bottom_y
@onready var roadside_offset_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_roadside_offset
@onready var player_width_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_player_width
@onready var roadside_object_width_line_edit : LineEdit = $HBoxContainer/RasterRoadVBoxContainer/GridContainer/line_ed_roadside_object_width



@onready var position_h_slider : HSlider = $HBoxContainer/RasterRoadVBoxContainer/h_slid_position 
@onready var position_spin: SpinBox = $HBoxContainer/RasterRoadVBoxContainer/spin_position 
@onready var zmap_text_edit : TextEdit = $HBoxContainer/RasterRoadVBoxContainer/txt_ed_zmap
@onready var texture_rect : TextureRect = $HBoxContainer/RasterRoadVBoxContainer/tex_rect_raster_road
@onready var dx_label : Label = $HBoxContainer/RasterRoadVBoxContainer/lbl_dx



var zmap: PackedFloat32Array = PackedFloat32Array()

@onready var export_step_spin : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/export_hbox/spin_export_step_size
@onready var total_length_label : Label = $HBoxContainer/TrackLayoutVBoxContainer/export_hbox/lbl_total_length
@onready var export_count_label : Label = $HBoxContainer/TrackLayoutVBoxContainer/export_hbox/lbl_export_count
#@onready var export_scroll_start_bg_a : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/export_hbox/spin_scroll_start_bg_a
#@onready var export_scroll_start_bg_b : SpinBox = $HBoxContainer/TrackLayoutVBoxContainer/export_hbox/spin_scroll_start_bg_b


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# track layout setup
	_create_file_dialogs()
	#add_start = Vector2(600,400)
	#var add_end = Vector2( 500,400)
	add_start = Vector2(0,0)
	var add_end = Vector2( 6,0)
	var seg := Segment.new( add_start, add_end, 0.0 )
	segments.append(seg)
	track_zoom = spin_zoom.value
	set_process(true)
	mouse_default_cursor_shape = Control.CURSOR_ARROW	
	
	spin_zoom.value = track_zoom
	
	# raster road setup
	screen_width_line_edit.text = "320"
	scroll_width_line_edit.text = "512"
	screen_height_line_edit.text = "224"
	background_points.clear()
	for i in range( 0, 25 ):
		var pt :Vector2 = Vector2 (  randf_range(0.0, 320.0), randf_range( 64.0, 144.0))
		background_points.append(pt)
	
	z_map_length_line_edit.text = "80"
	y_world_line_edit.text = "-15" 
	curve_dx_scale_line_edit.text = "0.0005"
	curve_bgdx_scale_line_edit.text = "0.008"
	position_h_slider.min_value = 0
	position_h_slider.max_value = 100
	position_h_slider.value = 0
	position_spin.value = 0
	export_step_spin.value = 0.15
	#export_scroll_start_bg_a.value = 100
	#export_scroll_start_bg_b.value = 64
	
	var image :Image = Image.create(int(screen_width_line_edit.text), int(screen_height_line_edit.text), false, Image.FORMAT_RGB8)
	image.fill( Color8(0,0,128))
	texture_rect.texture = ImageTexture.create_from_image(image)
	track_name.text = ""
	compute_raster_zmap()
	update_raster_road()
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass # var mp := get_local_mouse_position()
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var mp := get_local_mouse_position()

				selected_index = _pick_segment(mp)
				if selected_index >= 0:
					segments[selected_index].write_out()
					_updating_control = true
					spin_curve.editable = true
					spin_curve.value = segments[selected_index].curve
					spin_length.editable = true
					spin_length.value = segments[selected_index].length
					_updating_control = false
					
					status_label.text = "Selected segment %d" % selected_index
					queue_redraw()
				else:
					spin_curve.editable = false
					spin_length.editable = false
					status_label.text = "No selection"
					track_dragging = true
					track_drag_last_pt = mp
					queue_redraw()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				track_zoom += 10.0
				spin_zoom.value = track_zoom
				queue_redraw()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				track_zoom -= 10.0
				if track_zoom < spin_zoom.min_value:
					track_zoom = spin_zoom.min_value
				spin_zoom.value = track_zoom
				queue_redraw()
		else:
			if track_dragging: 
				track_dragging = false
			
	if event is InputEventMouseMotion and track_dragging:
		var new_mp : Vector2 = get_local_mouse_position()
		var diff_mp : Vector2 = new_mp - track_drag_last_pt
		track_offset += diff_mp
		track_drag_last_pt = new_mp
		queue_redraw()
func _draw() ->void:
	#draw_arc( Vector2( 100, 100 ), 100.0, -PI/2, PI/4, 50,  Color(1.0, 0.0, 0.0), 3 )
	for i in range(segments.size()):
		var s := segments[i]
		#print("DRAW i:%d s:%s e:%s curve:%s" % [i, s.p1, s.p2, s.curve])
		var col := SEG_COLOR
		if i == selected_index:
			col = SEG_SELECTED_COLOR
		elif i == hover_index:
			col = SEG_HOVER_COLOR
		if abs(s.curve) < NEAR_ZERO:
			draw_line(s.p1 * track_zoom + track_offset, s.p2* track_zoom + track_offset, col, 2.0)
			draw_circle(s.p1 * track_zoom + track_offset, 3.0, POINT_COLOR)
			draw_circle(s.p2 * track_zoom + track_offset, 3.0, POINT_COLOR)
		else:
			
			print("  DRAW cntr:%s rad:%f start:%f" % [ s.center, s.radius, s.arc_start_angle])
			draw_arc( s.center* track_zoom + track_offset, s.radius* track_zoom , s.arc_start_angle * PI/180, s.curve * PI/180 + s.arc_start_angle *PI/180, 50,  col, 2 )
			draw_circle(s.p1* track_zoom + track_offset, 3.0, POINT_COLOR)
			draw_circle(s.p2* track_zoom + track_offset, 3.0, POINT_COLOR)
			draw_circle(s.center* track_zoom + track_offset, 5.0, POINT_COLOR)
			
			
	total_road_length = 0.0
	for s in segments:
		total_road_length += s.length
		
	total_length_label.text = "%.3f" % total_road_length 
	export_count_label.text = "%d" % round( total_road_length / export_step_spin.value )		
			

func _create_file_dialogs() -> void:
	fd_open = FileDialog.new(); 
	add_child(fd_open)
	fd_open.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd_open.access = FileDialog.ACCESS_FILESYSTEM
	fd_open.filters = PackedStringArray(["*.json ; JSON files"])
	fd_open.ok_button_text = "Open"
	fd_open.file_selected.connect(_open_json_path)


	fd_save = FileDialog.new(); 
	add_child(fd_save)
	fd_save.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd_save.access = FileDialog.ACCESS_FILESYSTEM
	fd_save.filters = PackedStringArray(["*.json ; JSON files"])
	fd_save.current_file = "track.json"
	fd_save.ok_button_text = "Save"
	fd_save.file_selected.connect(_save_json_path)


	fd_export = FileDialog.new(); 
	add_child(fd_export)
	fd_export.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd_export.access = FileDialog.ACCESS_FILESYSTEM
	#fd_export.filters = PackedStringArray(["*.h ; C header files"])
	fd_export.current_file = "track_basename"
	fd_export.ok_button_text = "Save"
	fd_export.file_selected.connect(_export)
	
	
	fd_map = FileDialog.new(); 
	add_child(fd_map)
	fd_map.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd_map.access = FileDialog.ACCESS_FILESYSTEM
	fd_map.current_file = "map_basename"
	fd_map.ok_button_text = "Save"
	fd_map.file_selected.connect(_export_map)

func _pick_segment(p: Vector2) -> int:
	var best := -1
	var best_d := PICK_TOLERANCE
	for i in range(segments.size()):
		var s := segments[i]
		# check if curved
		var d: float = 1.79769e308
		if abs(s.curve) < NEAR_ZERO:
			d = _point_line_segment_distance(p, s.p1* track_zoom + track_offset, s.p2* track_zoom + track_offset)
		else:
			d = _point_curve_segment_distance(p, s.center* track_zoom + track_offset, s.radius, s.curve, s.arc_start_angle )
		
		print( "i: %d dist: %d" % [ i, d])
		if d <= best_d:
			best_d = d; best = i
	return best
	
static func _point_line_segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ab_len2 := ab.length_squared()
	if ab_len2 <= 1e-8:
		return p.distance_to(a)
	var t := ((p - a).dot(ab) / ab_len2 )
	var proj := a + ab * t
	var distance =  p.distance_to(proj)
	# is it on the line? ///https://paulbourke.net/geometry/pointlineplane/
	var u = (( p.x - a.x ) * ( b.x - a.x ) + ( p.y-a.y) * (b.y-a.y) )/( ab_len2 )
	if u > 1 or u < 0 :
		# not on the line segment, blow it out
		distance = 1.79769e308
	return distance

static func _mod_degrees( angle: float ) -> float :
	var ret_angle : float  = ( int(angle) % 360 ) + ( angle - floor( angle ) )
	if( ret_angle > 0.0 ):
		return ret_angle
		
	return ret_angle + 360.0

static func _point_curve_segment_distance(p: Vector2, center: Vector2, radius: float, curve: float, start_angle: float ) -> float:
	# distance of point from center 
	var line : Vector2  = p - center
	var dist : float = p.distance_to( center )
	var diff : float= abs( radius  * track_zoom - dist )
	var angle_degrees : float = _mod_degrees(  line.angle() * 180.0 / PI )
	var mod_start : float = _mod_degrees( start_angle )
	var mod_end : float = _mod_degrees( start_angle + curve )
	# checks counter clockwise 
	if curve < 0:
		var temp = mod_end
		mod_end = mod_start
		mod_start = temp
	
	if mod_start == 360.0 :
		mod_start = 0.0
	
	if mod_start > 0.0:
		mod_end = mod_end -mod_start
		angle_degrees = angle_degrees -mod_start
		mod_start = 0	
	
	print( "d: %d deg: %f curve: %f start: %f" % [ diff, angle_degrees, curve, start_angle ])
	print( " deg: %f start: %f end: %f" % [ angle_degrees, mod_start, mod_end ])
	if mod_start >= 0.0:
		mod_end = mod_end -mod_start
		if mod_end < 0.0:
			mod_end += 360.0
		angle_degrees = angle_degrees -mod_start
		if angle_degrees < 0.0:
			angle_degrees += 360.0
		mod_start = 0	 
	print( " SHIFT TO deg: %f start: %f end: %f" % [ angle_degrees, mod_start, mod_end ])
		
	if mod_start < angle_degrees and angle_degrees < mod_end:
		print("YES")
		return diff
		#if mod_start < angle_degrees or angle_degrees < mod_end:
			#print("YES2")
			#return diff
	print("NO")
	return 1.79769e308
	
	
	
func _open_json_path(path: String) -> void:
	print("open at %s" % path)
	var file = FileAccess.open( path, FileAccess.READ )
	if file.is_open():
		track_name.text = path
		var tmp_string = file.get_as_text()
		var json = JSON.new()
		var err = json.parse( tmp_string )
		if err == OK:
			var data = json.data
			if typeof( data ) == TYPE_ARRAY:
				print( data )
				segments.clear()
				for d in data:
					var seg := Segment.new( Vector2.INF, Vector2.INF, 0.0 )
					seg.from_dict(d)
					segments.append(seg)
				print( segments )
				queue_redraw()
			else:
				print( "unexpected data type" )
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", tmp_string, " at line ", json.get_error_line())
		
		
func _save_json_path(path: String) -> void:
	print("save at %s" % path)
	# open a file for writng
	var file = FileAccess.open( path, FileAccess.WRITE )
	if file.is_open():
		var dicts: Array[Dictionary] = []
		for s in segments:
			dicts.append(s.to_dict())
		var json_string = JSON.stringify(dicts)
		file.store_string(json_string)
	
	
func _export(path: String) -> void:
	var header_path : String = path + ".h"
	var source_path : String = path + ".c"
	var width = int(screen_width_line_edit.text)
	var scroll_width = int(scroll_width_line_edit.text)
	var height = int(screen_height_line_edit.text)
	
	var player_y : float = float(player_bottom_y_line_edit.text)	
	
	var zmap_length = int( z_map_length_line_edit.text )
	if zmap_length < 1 or zmap_length > height:
		return
	
	var scroll_vals : Array =  compute_scroll(0)

	var total_length : float  = scroll_vals[3]
	var step_size : float = export_step_spin.value
	var total_steps: int = int(total_length / step_size)
	var pos : float = 0.0
	var road_to_scroll_a_hash : Array = Array() 
	var road_to_bg_dx : Array = Array()
	
	#var bg_a_start : int = export_scroll_start_bg_a.value  
	#var bg_b_start : int = export_scroll_start_bg_b.value 
	var road_start = height - zmap_length
	var h_scroll_a_dict: Dictionary = Dictionary()
	#var h_scroll_b_dict: Dictionary = Dictionary()
	# calc all and get a cksum/hash for total
	#var background_a_position: float = 0.0
	#var background_b_position: float = 0.0
	for i in range(0, total_steps ): 
		scroll_vals =  compute_scroll(pos)
		var x_center: PackedFloat32Array  = scroll_vals[0]
		#var segline_z_index :int  = scroll_vals[1]
		var bg_dx :float  = scroll_vals[2]
		road_to_bg_dx.append( bg_dx )
		#print( "pos: %f z: %d bg dx: %f " % [ pos, segline_z_index, bg_dx  ])
		
		#var scroll_a_line_count = height - bg_a_start
		var scroll_a : ScrollValues = ScrollValues.new( road_start )
		# do road lines
		for x in x_center:
			scroll_a.h_scroll_vals.append( round ( x - width/2.0 ) ) # sega image 
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256) 
		ctx.update( scroll_a.h_scroll_vals.to_byte_array() )
		var res = ctx.finish()
		var hash_a = res.hex_encode()
		h_scroll_a_dict[ hash_a] = scroll_a
		road_to_scroll_a_hash.append( hash_a )
		
		## do backgroundscroll offsets
		#background_a_position += bg_dx
		#background_b_position += bg_dx/2.0  # slower scroll could just shift instead?
 
		pos = pos + step_size 
		
	print( "total steps: %d uniq-hashes A: %d  " % [total_steps, h_scroll_a_dict.size()])
		
	var scroll_center:int = round(( width - scroll_width )/2.0)
	
	var basename: String = path.substr(path.rfind('/')+1 ) 
	var src_file = FileAccess.open( source_path, FileAccess.WRITE )
	if src_file.is_open():
		src_file.store_string("#include <genesis.h>\n\n")
		
		var hash_to_offset: Dictionary = Dictionary()
 
		
		src_file.store_string("const s16 hscroll_offsets[] = {\n")
		var array_offset: int = 0
		for key in h_scroll_a_dict:
			var scrollvals : ScrollValues = h_scroll_a_dict[key]
			hash_to_offset[key] = array_offset
			src_file.store_string("  // offset %d  hash %s\n  " % [ array_offset, key ])
			for road_line in range( road_start, scrollvals.h_scroll_vals.size() ):
				var val:int = scrollvals.h_scroll_vals[road_line] + scroll_center
				src_file.store_string(" %d," % val )
				array_offset += 1
			src_file.store_string("\n")
			
		
		src_file.store_string("};\n\n")
	
		# use hash to offset to make LUT for position to scroll values
		src_file.store_string("const u16 pos_to_hscroll_offsets_index[] = {\n")
		for r in road_to_scroll_a_hash : 
			src_file.store_string(" %d," % hash_to_offset[r] )
		src_file.store_string("};\n\n")
	

		# store a background dx, Use fix16 for more actual scerolling positions of 512 wide bg image. 
		src_file.store_string("const fix16 pos_to_bg_dx[] = {\n")
		for bgdx in road_to_bg_dx:
			src_file.store_string(" FIX16( %0.3f )," % bgdx )
		src_file.store_string("};\n\n")
		
		src_file.store_string("const fastfix16 zmap[] = {\n")
		for i in range( 0, zmap_length ) : 
			src_file.store_string("  FASTFIX16( %0.3f )," % zmap[i])
		src_file.store_string("};\n\n")
			
		var base_z :int = round ( height - player_y )
		src_file.store_string("const fastfix16 scale_for_y[] = {\n")
		for i in range( 0, zmap_length ) : 
			src_file.store_string("  FASTFIX16( %0.3f )," % ( zmap[base_z]/ zmap[i] ) )
		src_file.store_string("};\n\n")
			
		
	var inc_file = FileAccess.open( header_path, FileAccess.WRITE )
	if inc_file.is_open():
		inc_file.store_string("#ifndef _%s_H_\n" % [ basename.to_upper() ] )
		inc_file.store_string("#define _%s_H_\n\n" % [ basename.to_upper() ] )
		inc_file.store_string("#include <genesis.h>\n\n")
		
		inc_file.store_string("#define ROAD_START_LINE %d \n" % [ road_start ] )
		inc_file.store_string("#define ZMAP_LENGTH %d \n\n" % [ zmap_length ] ) 
		
		# data for getting track position to lookup positions
		inc_file.store_string("// data for getting track position to lookup positions\n")
		inc_file.store_string("// total positions used for lookups\n")
		inc_file.store_string("#define POS_DATA_LEN %d \n" % [ total_steps ] ) 
		inc_file.store_string("// total length of all segment lengths from track editor\n")
		inc_file.store_string("const fastfix16 total_road_length = FASTFIX16( %f );\n" % [ total_road_length ] )
		inc_file.store_string("//  step size used by script to calculate scrolling data along track\n")
		inc_file.store_string("//  use with POS_DATA_LENGTH\n")
		inc_file.store_string("const fastfix16 hscroll_data_step_size = FASTFIX16( %f );\n\n" % [ step_size ] )
		
		
		inc_file.store_string("// horizontal scrolling offsets for use with \n")
		inc_file.store_string("// VDP_setHorizontalScrollLine()\n")
		inc_file.store_string("extern const s16 hscroll_offsets[];\n")
		inc_file.store_string("// points to start of horizontal scrolling offsets \n")
		inc_file.store_string("extern const u16 pos_to_hscroll_offsets_index[];\n")
		inc_file.store_string("// rate of change for background for current position.\n")
		inc_file.store_string("extern const fix16 pos_to_bg_dx[];\n\n")
		
		inc_file.store_string("// zmap \n")
		inc_file.store_string("extern const fastfix16 zmap[ZMAP_LENGTH];\n")
		inc_file.store_string("// scale values for rows/Ys \n")
		inc_file.store_string("extern const fastfix16 scale_for_y[ZMAP_LENGTH];\n\n")
		inc_file.store_string("#endif // _%s_H_\n" % [ basename.to_upper() ] )
		
	 

func update_bound( upper_left: Vector2, lower_right: Vector2, pt: Vector2 ) -> Array:
	if pt.x < upper_left.x:
		upper_left.x = pt.x
	if pt.y < upper_left.y:
		upper_left.y = pt.y
	if pt.x > lower_right.x:
		lower_right.x = pt.x
	if pt.y > lower_right.y:
		lower_right.y = pt.y
	return [upper_left, lower_right]


func _export_map(path: String) -> void:
	var header_path : String = path + ".h"
	var source_path : String = path + ".c"
	var image_path : String = path + ".png"
	#var width = int(screen_width_line_edit.text)
	#var scroll_width = int(scroll_width_line_edit.text)
	var height = int(screen_height_line_edit.text)
	var zmap_length = int( z_map_length_line_edit.text )
	if zmap_length < 1 or zmap_length > height:
		return
	
	var upper_left: Vector2 = Vector2.INF
	var lower_right: Vector2 = -Vector2.INF

			
	for i in range(segments.size()):
		var s := segments[i]
		print("mapping segment i:%d p1:%s p2:%s curve:%s rad:%s" % [i, s.p1, s.p2, s.curve, s.radius])

		if abs(s.curve) < NEAR_ZERO:
			# line
			if s.p1.x < upper_left.x:
				upper_left.x = s.p1.x
			if s.p1.y < upper_left.y:
				upper_left.y = s.p1.y
			if s.p2.x < upper_left.x:
				upper_left.x = s.p2.x
			if s.p2.y < upper_left.y:
				upper_left.y = s.p2.y
				
			if s.p1.x > lower_right.x:
				lower_right.x = s.p1.x
			if s.p1.y > lower_right.y:
				lower_right.y = s.p1.y
			if s.p2.x > lower_right.x:
				lower_right.x = s.p2.x
			if s.p2.y > lower_right.y:
				lower_right.y = s.p2.y
		else:
			# arc
			# recall I limit range from -270 to 270 degrees
			# if segment.curve
		
			# draw_arc( s.center* track_zoom + track_offset, s.radius* track_zoom , s.arc_start_angle * PI/180, s.curve * PI/180 + s.arc_start_angle *PI/180, 50,  col, 2 )
	 
			var start_angle: float =  s.arc_start_angle *PI/180
			print("start angle %f  arc %f" % [start_angle, s.arc_start_angle])
			if s.arc_start_angle < 0.0:
				while start_angle < 0.0:
					start_angle += 2.0*PI
			elif s.arc_start_angle > 360:
				while start_angle > 2.0*PI:
					start_angle -= 2.0*PI
			print("adj start angle %f  arc %f" % [start_angle, s.arc_start_angle])
			
			var end_angle: float = start_angle + s.curve * PI/180 
			if s.curve < 0.0:
				while end_angle < 0.0:
					end_angle += 2.0*PI
				var tmp_angle = start_angle
				start_angle = end_angle
				end_angle = tmp_angle		
				if end_angle < start_angle:
					end_angle += 2.0 * PI	
 
 
			print("final start angle %f" % start_angle)
			print("final end angle %f" % end_angle)
			
 

 			# TODO: There's gotta be a smarter way than this.
			# 1. Starting point of the arc could be part of BB
			var a1 : Vector2 = s.center
			a1.x = a1.x + cos( start_angle ) * s.radius
			a1.y = a1.y + sin( start_angle ) * s.radius 
			if a1.x < upper_left.x:
				upper_left.x = a1.x
			if a1.y < upper_left.y:
				upper_left.y = a1.y
			if a1.x > lower_right.x:
				lower_right.x = a1.x
			if a1.y > lower_right.y:
				lower_right.y = a1.y
			
			# 2. Ending point of the arc could be part of BB
			var a2 : Vector2 = s.center
			a2.x = a2.x + cos( end_angle ) * s.radius
			a2.y = a2.y + sin( end_angle ) * s.radius
			if a2.x < upper_left.x:
				upper_left.x = a2.x
			if a2.y < upper_left.y:
				upper_left.y = a2.y
			if a2.x > lower_right.x:
				lower_right.x = a2.x
			if a2.y > lower_right.y:
				lower_right.y = a2.y
				

			

					
			var pt_0: Vector2 = s.center + Vector2( s.radius, 0.0 )
			var pt_90: Vector2 = s.center + Vector2( 0.0, s.radius )
			var pt_180: Vector2 = s.center + Vector2( -s.radius, 0.0)
			var pt_270: Vector2 = s.center + Vector2( 0.0, -s.radius )
			

			
		#45 degrees :
#r = L*(180/pi)/a
		 #r = 2( 180/pi)/45 = 2.54647908947
		#
		#mapping segment i:0 p1:(0.0, 0.0) p2:(2.0, 0.0) curve:0.0 rad:-1.0
		#mapping segment i:1 p1:(2.0, 0.0) p2:(3.800633, 0.745846) curve:45.0 rad:2.54647908947033 << LOOKS GOOD
		#
		 #2.54647908947 * cos( 45deg ) = 1.80063263231
		 #2.54647908947 * sin (45deg ) = 1.80063263231  -> 2.54647908947 - 1.80063263231 = 0.74584645716
		#
			 #2 + 1.8  ~3.8
			 #0 + 0.745846 ~
		#UPPER_LEFT: (0.0,-0.00000010273021)  LOWER_RIGHT: (3.80063271522522,0.74584633111954) 
			
 			# TODO: There's gotta be a smarter way than this.
			# if curve < 90 possibly 1 to add,
			if abs(s.curve) < 90.0:
				if start_angle < PI/2.0 and end_angle > PI/2.0:
					var result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
				elif start_angle < PI and end_angle > PI:
					var result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
				elif start_angle < 3.0*PI/2.0 and end_angle > 3.0*PI/4.0:
					var result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
				elif start_angle < 2.0*PI and end_angle > 2.0 * PI:
					var result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					
				
			elif abs(s.curve) >=90.0 and abs(s.curve) < 180.0:  # at least 1 to add
				if start_angle < PI/2.0 : # and end_angle > PI/2.0:
					var result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > PI:
						result = update_bound( upper_left, lower_right, pt_180 ) 
						upper_left = result[0]
						lower_right = result[1]
						
				elif start_angle < PI : # and end_angle > PI:
					var result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
						
					if end_angle > 3.0*PI/2.0:
						result = update_bound( upper_left, lower_right, pt_270 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 3.0*PI/2.0 : #and end_angle > 3.0*PI/4.0:
					var result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 2.0*PI:
						result = update_bound( upper_left, lower_right, pt_0 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 2.0*PI : # and end_angle > 2.0 * PI: 
					var result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 5.0*PI/2.0:
						result = update_bound( upper_left, lower_right, pt_90 ) 
						upper_left = result[0]
						lower_right = result[1]
						
			elif abs(s.curve) >=180.0 and abs(s.curve) < 270.0:  # at least two to add
				if start_angle < PI/2.0 : # and end_angle > PI/2.0:
					var result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 3.0*PI/2.0 :
						result = update_bound( upper_left, lower_right, pt_270 ) 
						upper_left = result[0]
						lower_right = result[1]
						
				elif start_angle < PI : # and end_angle > PI:
					var result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 2.0 * PI:
						result = update_bound( upper_left, lower_right, pt_0 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 3.0*PI/2.0 : #and end_angle > 3.0*PI/2.0:
					var result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 5.0*PI/2.0:
						result = update_bound( upper_left, lower_right, pt_90 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 2.0*PI : # and end_angle > 2.0 * PI: 
					var result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 3.0*PI:
						result = update_bound( upper_left, lower_right, pt_180 ) 
						upper_left = result[0]
						lower_right = result[1]
			 
			
			else:  # should max at 270, add e
				if start_angle < PI/2.0 : # and end_angle > PI/2.0:
					var result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle >= 2*PI :
						result = update_bound( upper_left, lower_right, pt_0 ) 
						upper_left = result[0]
						lower_right = result[1]
						
				elif start_angle < PI : # and end_angle > PI:
					var result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle >=  5.0*PI/2.0:
						result = update_bound( upper_left, lower_right, pt_90 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 3.0*PI/2.0 :  
					var result = update_bound( upper_left, lower_right, pt_270 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 6.0*PI/2:
						result = update_bound( upper_left, lower_right, pt_180 ) 
						upper_left = result[0]
						lower_right = result[1]
				elif start_angle < 2.0*PI : # and end_angle > 2.0 * PI: 
					var result = update_bound( upper_left, lower_right, pt_0 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_90 ) 
					upper_left = result[0]
					lower_right = result[1]
					result = update_bound( upper_left, lower_right, pt_180 ) 
					upper_left = result[0]
					lower_right = result[1]
					if end_angle > 7.0*PI/2.0:
						result = update_bound( upper_left, lower_right, pt_270 ) 
						upper_left = result[0]
						lower_right = result[1]
							
							
 
 
			
	print("UPPER_LEFT: (%s,%s)  LOWER_RIGHT: (%s,%s)" % [ upper_left.x, upper_left.y, lower_right.x, lower_right.y])
	var map_width :float = lower_right.x - upper_left.x
	var map_height : float = lower_right.y - upper_left.y
	var map_scale : float = 64.0/map_width
	if map_height > map_width:
		map_scale = 48.0 / map_height
	print("map_width: %f  map_height: %f map_scale %s " % [ map_width, map_height, map_scale ] )
	
	# use 8 pixel margein all around the map
	var map_offset : Vector2 = Vector2( 8.0, 8.0 ) - map_scale * upper_left
	var image :Image = Image.create(64 + 16, 48 +16, false, Image.FORMAT_RGB8)
	image.fill( Color.BLACK ) 
	 
	var path_points: PackedVector2Array = []
	 
	# get step size 
	var step_size : float = export_step_spin.value
	#var total_steps: int = total_road_length / step_size
	
	#var absolute_position : float = 0.0
	#var curr_seg : int = 0
	var prev_leftover : float = 0.0
	#for i in range(0, total_steps ): 
	for i in range(segments.size()):
		var s: Segment = segments[i]
		if abs(s.curve) < NEAR_ZERO:
			# straight segment. Rise ovah run baby
			var slope = ( s.p2 - s.p1 ).normalized()
			var step_vec : Vector2 = slope * step_size
			print("P1: (%f, %f), P2: (%f, %f) Slope: (%f, %f) step vec (%f, %f)" %[ s.p1.x, s.p1.y, s.p2.x, s.p2.y, slope.x, slope.y, step_vec.x,  step_vec.y ])
			# var steps_in_seg : int = s.length / step_size
			# compute points along the line (pt1 and pt2
			var seg_pos = - prev_leftover
			var curr_pt = s.p1 - slope * prev_leftover
			while seg_pos < s.length:
				if seg_pos >= 0: 
					var adjusted_pt = map_scale* curr_pt + map_offset
					print("curr_pt: (%f, %f) adj_pt( %f, %f) " % [ curr_pt.x, curr_pt.y, adjusted_pt.x, adjusted_pt.y ])
					image.set_pixel(round(adjusted_pt.x), round(adjusted_pt.y), Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)+1, round(adjusted_pt.y)+1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)+1, round(adjusted_pt.y)-1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)-1, round(adjusted_pt.y)+1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)-1, round(adjusted_pt.y)-1, Color.WHITE)
					path_points.append( adjusted_pt )
				seg_pos += step_size
				curr_pt = curr_pt + step_vec
				prev_leftover = s.length - seg_pos
			
		else:
			# curved,  L = theta * radius
			# current leftover radius
			var tmp_rad : float = 0.0
			var step_rad : float = step_size/ s.radius
			if prev_leftover > NEAR_ZERO:
				tmp_rad = prev_leftover / s.radius 

			if s.curve < 0.0:
				tmp_rad = tmp_rad * -1.0
				step_rad = step_rad * -1.0
					
		 
			
			var curr_rad = (s.arc_start_angle*PI/180) - tmp_rad
			print("prev leftover: %f arc start angle: %f curr_rad %f step_rad %f" % [prev_leftover, s.arc_start_angle, curr_rad, step_rad])
			var seg_pos = - prev_leftover
			while seg_pos < s.length:
				if seg_pos >= 0.0:
					var curr_pt : Vector2 = s.center + ( s.radius * Vector2( cos( curr_rad), sin(curr_rad)) )
					var adjusted_pt = map_scale *  curr_pt + map_offset 
					print("c center: (%f, %f) theta: %f curr_pt: (%f, %f) adj_pt( %f, %f) " % [ s.center.x, s.center.y, curr_rad, curr_pt.x, curr_pt.y, adjusted_pt.x, adjusted_pt.y ])
					image.set_pixel(round(adjusted_pt.x), round(adjusted_pt.y), Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)+1, round(adjusted_pt.y)+1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)+1, round(adjusted_pt.y)-1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)-1, round(adjusted_pt.y)+1, Color.WHITE)
					image.set_pixel(round(adjusted_pt.x)-1, round(adjusted_pt.y)-1, Color.WHITE)
					path_points.append( adjusted_pt )
				seg_pos += step_size
				curr_rad = curr_rad + step_rad
				prev_leftover = s.length - seg_pos
				
				
	image.save_png(image_path);
			
 
	var src_file = FileAccess.open( source_path, FileAccess.WRITE )
	if src_file.is_open():
		src_file.store_string("#include <genesis.h>\n\n")
		  
		src_file.store_string("const s16 map_path[] = {\n") 
		for pt in path_points:    
			src_file.store_string(" %d, %d," % [ round(pt.x), round(pt.y)] ) 
			src_file.store_string("\n")	
		
		src_file.store_string("};\n") 

	var basename: String = path.substr(path.rfind('/')+1 ) 
	var inc_file = FileAccess.open( header_path, FileAccess.WRITE )
	if inc_file.is_open():
		inc_file.store_string("#ifndef _%s_H_\n" % [ basename.to_upper() ] )
		inc_file.store_string("#define _%s_H_\n\n" % [ basename.to_upper() ] )
		inc_file.store_string("#include <genesis.h>\n\n")
		 
		inc_file.store_string("#define MAP_PATH_LENGTH %d \n\n" % [ path_points.size() * 2 ] ) 
 
		inc_file.store_string("extern const fix16 map_path[];\n\n")
		inc_file.store_string("#endif // _%s_H_\n" % [ basename.to_upper() ] )
				
	#for i in range(segments.size()):
		#var s := segments[i]
 #
		#if abs(s.curve) < NEAR_ZERO:
			##draw_line(s.p1 * track_zoom + track_offset, s.p2* track_zoom + track_offset, col, 2.0)
 			#pass:
		#else: 
			##print("  DRAW cntr:%s rad:%f start:%f" % [ s.center, s.radius, s.arc_start_angle])
			#
	
		
func compute_raster_zmap() -> void:
	# **`Z = Y_World  /( Y_screen -  (screen_height/2) )`**
	#  `Y_world` is th edifference between the ground and camera height (and is negative)
	var height  :int= int(screen_height_line_edit.text)
	var y_world : float = float(y_world_line_edit.text)
	var player_y : float = float(player_bottom_y_line_edit.text)
	
	var zmap_length = int( z_map_length_line_edit.text )
	if zmap_length < 1 or zmap_length > height:
		return
	pass
	zmap.clear()
	zmap_text_edit.clear()
	var text : String = ""
	for i in range( 0, zmap_length ) :
		# the triangle
		#   y_screen/dist = y_world/z_world    dist is dist to screen
		#   y_screen = (y_world*dist)/z_world 
		# Lou goes on and says dist=1  (arbitrary)
		#   y_screen = (y_world)/z_world 
		# **but this puts the center  of the view at the upper corner of the screen**
		#
		# to center on the display, shift  by half the resolution (y_resooution/2)
		#
		#     y_screen = (y_world)/z_world + ( y_resolution/2)
		#     y_screen - ( y_resolution/2 ) = y_world/z_world
		#     Z = Y_world / (Y_screen - (height_screen / 2))
		#
		#  In my particular case, screen center isn't really the 
		#  center of the display, I want the vanishing point to be at the "top"
		# of z so really  zmap length is my height/2.0
		# var z = y_world / ( float(  i) - (float(height)/2.0) )  
		var z : float = y_world / ( float(  i- zmap_length ) )
		zmap.append( z )
	
	var base_z : int = round(height - player_y)
	for i in range( 0, zmap_length ) : 
		zmap_text_edit.text  += "i: %d z %f  scale:%f \n" % [ i, zmap[i], zmap[base_z]/ zmap[i] ]


func compute_scroll( scroll_pos : float) ->  Array:
		#
	var pos : float = scroll_pos
	var width = int(screen_width_line_edit.text)
	var height = int(screen_height_line_edit.text)
	var zmap_length = int( z_map_length_line_edit.text )
 
	#var road_pos : float = -1.0
 
	# create array for road centers
	var x_center: PackedFloat32Array = PackedFloat32Array()
	x_center.resize( height )
	for y in range( height-1, height-zmap_length-1, -1 ):
		x_center[y] = width/2.0
	

	# get total road length and segment we're in
	# position slider/spinner tells us which node we're in.
	total_road_length = 0.0
	var preceding_road_length : float = 0.0
	var current_segment : int = 0 
	for i in range( 0, segments.size() ): 
		total_road_length += segments[i].length
		if total_road_length < pos:
			#if current position > accumlate length, it's not this segment
			current_segment = i + 1 
			preceding_road_length = total_road_length
			

	
	export_count_label.text = "%d" % ( total_road_length / export_step_spin.value )
	
	# get scale factor for curve/angle
	var curve_dx_scale : float = float(curve_dx_scale_line_edit.text)
	var bg_dx_scale : float = -1.0 * float( curve_bgdx_scale_line_edit.text )
	
	# get dx for two segments
	var base_segment_dx: float = segments[current_segment].curve * curve_dx_scale
	var base_segment_len: float = segments[current_segment].length
	var base_segement_bg_dx : float = segments[current_segment].curve * bg_dx_scale
	var next_segment: int = current_segment + 1
	if next_segment >= segments.size() :
		next_segment = 0
	var next_segment_dx: float = segments[next_segment].curve * curve_dx_scale
	#var next_segment_len: float = segments[next_segment].length 
	var next_segement_bg_dx : float = segments[next_segment].curve * bg_dx_scale
	
	
	# calculate segment z position based on zmap
	# how far are we from next segment
	var segline_dist : float = base_segment_len - ( pos - preceding_road_length )
	
	var segline_z_index: int = -1 
	var last_diff = 1.79769e308
	for i in range( 0, zmap_length ) :
		var z = zmap[i]
		var diff = abs( z - segline_dist )
		if diff < last_diff:
			last_diff = diff
			segline_z_index = height - i -1
			
		
	var current_x = width/2.0  # half of screen width is center
	var dx : float = 0.0
	var ddx : float = 0.0
	for y in range( height-1, height-zmap_length-1, -1 ):
		if y > segline_z_index : # below in screen coordinates is greater than
			dx = base_segment_dx
		else:
			dx = next_segment_dx
		ddx += dx
		current_x += ddx
		x_center[y] = current_x

	var bg_dx : float = 0.0
	if segline_z_index < height - 1:
		bg_dx = base_segement_bg_dx
	else:
		bg_dx = next_segement_bg_dx
		
	dx_label.text = "curr: %d dx: %f next: %d dx: %f \nsegline dist: %f segline: %d bg_dx: %f" %[ current_segment, base_segment_dx, next_segment, next_segment_dx, segline_dist, segline_z_index, bg_dx]
	#print("ROWS IN X_CENTER %d " % x_center.size())
	return [ x_center, segline_z_index, bg_dx, total_road_length ]
	


func update_raster_road() -> void:
	#
 
	var width = int(screen_width_line_edit.text)
	#var scroll_width = int(scroll_width_line_edit.text)
	var height = int(screen_height_line_edit.text)
	var zmap_length = int( z_map_length_line_edit.text )
	if zmap_length < 1 or zmap_length > height:
		return
		
	var scroll_vals : Array =  compute_scroll(position_spin.value)
	var x_center: PackedFloat32Array  = scroll_vals[0]
	var segline_z_index :int  = scroll_vals[1]
	var bg_dx :float  = scroll_vals[2]
	var road_length : float  = scroll_vals[3]
	
	position_h_slider.max_value = road_length
	position_spin.max_value = road_length
	
	# Draw the raster road
	var image :Image = Image.create(int(screen_width_line_edit.text), int(screen_height_line_edit.text), false, Image.FORMAT_RGB8)
	image.fill( Color.DARK_BLUE ) 
	
	var ground_rect: Rect2i = Rect2i( 0, height - zmap_length, width, zmap_length)
	image.fill_rect(ground_rect, Color.FOREST_GREEN)
	var road_line_width: float = float(width);
	var road_size_step: float = road_line_width / float(zmap_length)
	for y in range( height-1, height-zmap_length-1, -1 ):
		if y != segline_z_index:
			var x = x_center[y] - road_line_width/2  # ( width - road_line_width ) / 2   
			var road_line: Rect2i = Rect2i(round(x), y, round(road_line_width), 1 );
			image.fill_rect(road_line, Color.BLACK)
		else:
			var road_line: Rect2i = Rect2i(0, y, width, 1 );
			image.fill_rect(road_line, Color.YELLOW)
		road_line_width -= road_size_step
 

	#for pt in background_points:
	for i in range( 0, background_points.size() ):
		print("p %f BGX  %f" % [ position_spin.value, background_points[i].x] )
		background_points[i].x += bg_dx
		if bg_dx < 0.0 :
			if background_points[i].x < 0.0 :
				background_points[i].x = width
		else:
			if background_points[i].x > width:
				background_points[i].x = 0.0
		
		#image.set_pixel( int(pt.x), int(pt.y), Color.WHITE)
		image.set_pixelv( background_points[i], Color.WHITE)
		
		
	texture_rect.texture = ImageTexture.create_from_image(image)




func _on_btn_add_pressed() -> void:
	if segments.size() <= 0: 
		return
	# get last segment when adding
	selected_index = segments.size()-1
	add_start = segments[selected_index].p2
	# is last segment straight? 
	if abs(segments[selected_index].curve) < NEAR_ZERO:
		segments[selected_index].curve = 0.0
		var end_point = add_start + ( segments[selected_index].p2 - segments[selected_index].p1)
		var seg := Segment.new(add_start, end_point , 0.0)
		segments.append(seg)
		selected_index = segments.size() - 1
		add_mode = false
		_updating_control = true
		status_label.text = "Segment added"
		spin_curve.editable = true
		spin_curve.value = 0.0
		spin_length.editable = true
		spin_length.value = (segments[selected_index].p2 - segments[selected_index].p1).length()
		_updating_control = false
		queue_redraw() 
	else:
		# not straight
		#print("---ADDING TO CURVED---------")
		# we know add start, from previous semgent p2 and
		# we can ssume lenght should be the previous segment leongth
		#  but we don't know the angle the line sghould oriented without some calculation
		#  * the curve is the total angle of the arc
		#  * the line coming off the arc should be a tangent
		var curr_length = segments[selected_index].length
		var curr_angle = segments[selected_index].curve * PI/180 
		#print( " curr_angle %f" % segments[selected_index].curve )
		var curr_end_point =  segments[selected_index].p2
		var curr_center =  segments[selected_index].center
		curr_angle = ( curr_end_point - curr_center).angle() + (PI/2 if curr_angle > 0 else - PI/2)
		#print( " updated curr_angle %f" %[ curr_angle * 180/PI ])
 
		var end_point = add_start + curr_length * Vector2( cos( curr_angle), sin( curr_angle))
		#print("Add Start %s end %s   angle %f  off( deg) %f" % [add_start, end_point, curr_angle*180/PI, segments[selected_index].arc_start_angle ])
		var seg := Segment.new(add_start, end_point , 0.0)
		#print("SEG: %s %s" % [seg.p1, seg.p2] )
		segments.append(seg)
		selected_index = segments.size() - 1
		add_mode = false
		status_label.text = "Segment added"
		
		_updating_control = true
		spin_curve.editable = true
		spin_curve.value = 0.0
		spin_length.editable = true
		spin_length.value = curr_length
		_updating_control = false
		
		#print(" double check start %s end %s   angle %f" % [segments[selected_index].p1, segments[selected_index].p2, segments[selected_index].curve])
		
		#print("------ADDED TO CURVED---------")
		queue_redraw() 
		
		
 

func _on_btn_delete_pressed() -> void:
	segments.remove_at(segments.size()-1)
	selected_index = -1
	spin_curve.editable = false
	status_label.text = "Deleted segment"
	queue_redraw()
 

func _on_spin_curve_value_changed(value: float) -> void:
	if _updating_control == true:
		return
	if selected_index == 0:
		spin_curve.value = 0.0
	if selected_index > 0 and selected_index < segments.size():
		segments[selected_index].curve = value
		if abs(value) > NEAR_ZERO:
			var new_pt = _compute_curve_orientation()
			print( "old %s   new %s" % [segments[selected_index].p2, new_pt])
			segments[selected_index].p2 = new_pt
		else: 
			# get previous angle and set pt2 by length and prev angle	
			var prev_start_pt =  segments[selected_index-1].p1
			var prev_end_point =  segments[selected_index-1].p2
			
			var temp = ( prev_end_point - prev_start_pt ).normalized()		
			var new_pt = segments[selected_index].p1 + segments[selected_index].length *temp
			segments[selected_index].p2 = new_pt
			spin_curve.value = 0.0
	 
		recompute_segments()
		queue_redraw()


func _on_spin_length_value_changed(value: float) -> void:
	
	if _updating_control == true:
		return
	if selected_index >= 0 and selected_index < segments.size():
		segments[selected_index].length = value
		if abs( segments[selected_index].curve ) < NEAR_ZERO:
			var new_pt = segments[selected_index].p1 + value * ( segments[selected_index].p2 -segments[selected_index].p1).normalized()
			#var diff = new_pt - segments[selected_index].p2
			segments[selected_index].p2 = new_pt
			#if selected_index < segments.size() -1:
				#_shift_segments( diff )
		else:
			var new_pt = _compute_curve_orientation()
			#var diff = new_pt - segments[selected_index].p2
			print( "old %s   new %s" % [segments[selected_index].p2, new_pt])
			segments[selected_index].p2 = new_pt
			# will need to rotate and translate later segments
			pass
		recompute_segments()
		queue_redraw()
	

#func _shift_segments(shift: Vector2) -> void:
	#for i in range( selected_index +1, segments.size() ):
		#segments[i].p1 += shift
		#segments[i].p2 += shift
	
	

func _compute_curve_orientation() -> Vector2:
	## we know starting point is pt1
	# we know that arc_len = (theta / 360) * 2 * pi * radius
	#           (wikipedia says   s = ( PI * r * theta)/180 = 2*PI*r * theta / 360 )
	#  therefor radius = arc_len * 360 / ( theta * 2 * pi )
	#  
	#  	recall degrees to radians is    t * PI /180  = t * 2*pi / 360 

	#      radius = arc_len / theta          

	# which matches wikipedia if theta is radians,   arc_len = radius * theta
	# 

	# use previous segment for initial angle since curve builds from prev seg
	var prev_start_pt =  segments[selected_index-1].p1
	var prev_end_point =  segments[selected_index-1].p2
	var prev_curve = segments[selected_index-1].curve
	var new_end = Vector2.INF
	if abs(prev_curve) < NEAR_ZERO:
		# previous sgment is a  straight line,
		segments[selected_index-1].curve = 0.0
		# angle of prev segment is 
		var prev_angle = ( prev_end_point - prev_start_pt ).angle()
		print( "prev angle: %s " % prev_angle )
		# get line perpendicular to straight line so we can find our circle center.
		var temp = ( prev_end_point - prev_start_pt ).normalized()
		print( "temp: %s " % temp )
		var arc_len = segments[selected_index].length
		var theta = segments[selected_index].curve 
		var perp = Vector2( -temp.y, temp.x ) if theta > 0 else Vector2( temp.y, -temp.x ) 
		print( "  perp : %s " % perp )
		
		print("theta: %f" % theta)
		var radius = arc_len * 360 / abs( theta * 2 * PI )
		print("rad: %f" % radius)
		segments[selected_index].radius = radius
		
		var center = prev_end_point + perp * radius
		segments[selected_index].center = center
		print( "    center : %s " % center )
		
		# offset for drawing purposes?  *IMP* add or subtract 90 degrees
		#   because ARc CENTER is perpendicular to the previous line.
		var arc_start_angle = prev_angle  + (PI/2 if theta < 0 else -PI/2)
		segments[selected_index].arc_start_angle = arc_start_angle * 180/PI
		print("offset angle: %f" % segments[selected_index].arc_start_angle)
		new_end = Vector2(  center.x + radius * cos(arc_start_angle + theta*PI/180 ), center.y + radius* sin(arc_start_angle + theta*PI/180))
	else:
		var prev_angle = prev_curve
		print( "prev angle: %s " % prev_angle )
		
		var arc_len = segments[selected_index].length
		var theta = segments[selected_index].curve 
		var prev_center = segments[selected_index-1].center
		var perp = ( prev_end_point - prev_center ).normalized()
		if ( theta > 0 and prev_angle > 0) or ( theta< 0 and prev_angle < 0 ):
			perp = perp * -1.0
		print( "  perp : %s " % perp )
		print("theta: %f" % theta)
		var radius = arc_len * 360 / abs( theta * 2 * PI )
		print("rad: %f" % radius)
		segments[selected_index].radius = radius
		
		var center = prev_end_point + perp * radius
		segments[selected_index].center = center
		print( "    center : %s " % center )
		
		var arc_start_angle = ( prev_end_point - center ).angle() 
		print(">> offset angle: %f" % arc_start_angle)
		segments[selected_index].arc_start_angle = arc_start_angle * 180/PI
		new_end = Vector2(  center.x + radius * cos(arc_start_angle + theta*PI/180 ), center.y + radius* sin(arc_start_angle + theta*PI/180))
	
		print("<> new end: %s" % new_end)
	return new_end
	
	


func _on_line_ed_curve_dx_scale_text_changed(new_text: String) -> void:
	if new_text.is_valid_int() or new_text.is_valid_float():
		update_raster_road() 


func _on_lin_ed_zmap_length_text_changed(new_text: String) -> void:
	if new_text.is_valid_int() or new_text.is_valid_float():
		compute_raster_zmap()
		update_raster_road()


func _on_lin_ed_y_world_text_changed(new_text: String) -> void:
	if new_text.is_valid_int(): 
		compute_raster_zmap()
		update_raster_road()


func _on_lin_ed_screen_width_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		update_raster_road()


func _on_lin_ed_screen_height_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		update_raster_road()


func _on_h_slid_position_drag_ended(value_changed: bool) -> void:
	if value_changed:
		var val = position_h_slider.value
		position_spin.value = val
		update_raster_road()


func _on_h_slid_position_value_changed(value: float) -> void:
	position_spin.value = value 


func _on_spin_position_value_changed(value: float) -> void:
	position_h_slider.value = value
	update_raster_road()


func _on_btn_export_pressed() -> void:
	fd_export.popup_centered_ratio(0.75)


func _on_btn_save_pressed() -> void:
	fd_save.current_path = track_name.text
	fd_save.popup_centered_ratio(0.75)


func _on_btn_load_pressed() -> void:
	fd_open.popup_centered_ratio(0.75)


func _on_spin_export_step_size_value_changed(value: float) -> void:
	export_count_label.text = "%d" % ( total_road_length / value )


func _on_btn_close_pressed() -> void:
	if segments.size() <= 1: 
		return
	# get last segment when adding
	selected_index = segments.size()-1
	add_start = segments[selected_index].p2
	
	var end_point = segments[0].p1
	var seg := Segment.new(add_start, end_point , 0.0)
	segments.append(seg)
	selected_index = segments.size() - 1
	add_mode = false
	_updating_control = true
	status_label.text = "Closer added"
	spin_curve.editable = true
	spin_curve.value = 0.0
	spin_length.editable = true
	spin_length.value = (segments[selected_index].p2 - segments[selected_index].p1).length()
	_updating_control = false
	queue_redraw() 


func _on_lin_ed_scroll_width_text_changed(new_text: String) -> void:
	if new_text.is_valid_int() or new_text.is_valid_float():
		update_raster_road()
	update_raster_road()
	


func _on_btn_minimap_pressed() -> void:
	fd_map.popup_centered_ratio(0.75) 


func _on_btn_refresh_pressed() -> void:
	recompute_segments()
	queue_redraw() 
	
func recompute_segments() -> void :
	print("######## RECOMPUTE SEGMENTS ##################################")
	
	
	if segments.size() == 1: 
		return
	if selected_index == segments.size() - 1 : 
		# last segment. nothing to do
		return
		
	print(" - - - CURRENT SEGMENTS - - - ")
	for seg in segments:
		seg.write_out()
		
	var start_index : int= selected_index
	if start_index < 0:
		start_index = 0
		
	
	
	# Get initial conditions.
	for prev_index in range( start_index, segments.size() - 1 ):
		print("------------------\nINDEX: %d" % [prev_index] )
		var prev_segment : Segment = segments[prev_index]
		var next_segment : Segment = segments[prev_index+1]
		
		var prev_angle_rad : float = 0.0
		
		
		# act as if we're adding a segment 
		var temp_segment : Segment 
		if abs(prev_segment.curve) < NEAR_ZERO  : 
			var end_pt : Vector2 = ( prev_segment.p2 -prev_segment.p1) + prev_segment.p2
			temp_segment  = Segment.new( prev_segment.p2, end_pt, 0.0 )
			
			
		else:
			# not straight
			var prev_length : float = prev_segment.length
			var prev_end_point : Vector2 = prev_segment.p2
			var prev_center : Vector2 = prev_segment.center
			
			prev_angle_rad = prev_segment.curve * PI/180 
			prev_angle_rad = ( prev_end_point- prev_center).angle() + (PI/2 if prev_angle_rad > 0 else - PI/2)
			var end_pt : Vector2 = prev_segment.p2 + prev_length * Vector2( cos( prev_angle_rad), sin( prev_angle_rad))
			temp_segment = Segment.new( prev_segment.p2, end_pt, 0.0 )
			
		print(" -> PREV curve %02f rad %0.2f" % [ prev_segment.curve, prev_angle_rad])
			
		# Apply ACTUAL next segment values as-if curve was changed.
		if abs(next_segment.curve) > NEAR_ZERO:
			# update temp to match `next segment` 
			var result  = _recompute_curve_orientation(prev_segment, next_segment)
			temp_segment.length = next_segment.length
			temp_segment.curve = next_segment.curve
			temp_segment.radius = next_segment.radius
			temp_segment.arc_start_angle = next_segment.arc_start_angle
			temp_segment.center = next_segment.center
			temp_segment.p2 =result
		else:  
			## should only need to adjust length if not curvy
			temp_segment.length = next_segment.length
			var new_end = ( temp_segment.p2 - temp_segment.p1 ).normalized() * temp_segment.length
			temp_segment.p2 = new_end + temp_segment.p1
			
			
			
		segments[prev_index+1] = temp_segment
			

	print(" - - - UPDATED SEGMENTS - - - ")
	for seg in segments:
		seg.write_out()
		
	total_length_label.text = str( total_road_length )
	export_count_label.text = "%d" % ( total_road_length / export_step_spin.value )
	
	
	
# params are custom class , so changes to next_seg will be kept
func _recompute_curve_orientation( prev_seg :Segment, next_seg: Segment) -> Vector2:
	## we know starting point is pt1
	# we know that arc_len = (theta / 360) * 2 * pi * radius
	#           (wikipedia says   s = ( PI * r * theta)/180 = 2*PI*r * theta / 360 )
	#  therefor radius = arc_len * 360 / ( theta * 2 * pi )
	#  
	#  	recall degrees to radians is    t * PI /180  = t * 2*pi / 360 

	#      radius = arc_len / theta          

	# which matches wikipedia if theta is radians,   arc_len = radius * theta
	# 

	# use previous segment for initial angle since curve builds from prev seg
	var prev_start_pt =  prev_seg.p1
	var prev_end_point =  prev_seg.p2
	var prev_curve = prev_seg.curve
	var new_end = Vector2.INF
	if abs(prev_curve) < NEAR_ZERO:
		print("PREV SEG STRAIGHT")
		# previous sgment is a  straight line,
		prev_seg.curve = 0.0
		# angle of prev segment is 
		var prev_angle = ( prev_end_point - prev_start_pt ).angle()
		#print( "prev angle: %s " % prev_angle )
		# get line perpendicular to straight line so we can find our circle center.
		var temp = ( prev_end_point - prev_start_pt ).normalized()
		#print( "temp: %s " % temp )
		var arc_len = next_seg.length
		var theta = next_seg.curve 
		var perp = Vector2( -temp.y, temp.x ) if theta > 0 else Vector2( temp.y, -temp.x ) 
		#print( "  perp : %s " % perp )
		
		#print("theta: %f" % theta)
		var radius = arc_len * 360 / abs( theta * 2 * PI )
		#print("rad: %f" % radius)
		next_seg.radius = radius
		
		var center = prev_end_point + perp * radius
		next_seg.center = center
		#print( "    center : %s " % center )
		
		# offset for drawing purposes?  *IMP* add or subtract 90 degrees
		#   because ARc CENTER is perpendicular to the previous line.
		var arc_start_angle = prev_angle  + (PI/2 if theta < 0 else -PI/2)
		next_seg.arc_start_angle = arc_start_angle * 180/PI
		print("arc start angle: %f" % next_seg.arc_start_angle)
		new_end = Vector2(  center.x + radius * cos(arc_start_angle + theta*PI/180 ), center.y + radius* sin(arc_start_angle + theta*PI/180))
	else:
		print("PREV SEG STRAIGHT")
		var prev_angle = prev_curve
		#print( "prev angle: %s " % prev_angle )
		
		var arc_len = next_seg.length
		var theta = next_seg.curve 
		var prev_center = prev_seg.center
		var perp = ( prev_end_point - prev_center ).normalized()
		if ( theta > 0 and prev_angle > 0) or ( theta< 0 and prev_angle < 0 ):
			perp = perp * -1.0
		#print( "  perp : %s " % perp )
		#print("theta: %f" % theta)
		var radius = arc_len * 360 / abs( theta * 2 * PI )
		#print("rad: %f" % radius)
		next_seg.radius = radius
		
		var center = prev_end_point + perp * radius
		next_seg.center = center
		print( "    center : %s " % center )
		
		var arc_start_angle = ( prev_end_point - center ).angle() 
		print(">> arc start angle: %f" % arc_start_angle)
		next_seg.arc_start_angle = arc_start_angle * 180/PI
		new_end = Vector2(  center.x + radius * cos(arc_start_angle + theta*PI/180 ), center.y + radius* sin(arc_start_angle + theta*PI/180))
	
		print("<> new end: %s" % new_end)
	return  new_end 
	
	


func _on_btn_reset_pressed() -> void:
	# Create dialog
	var dialog = ConfirmationDialog.new() 
	dialog.title = "Reset Track" 
	dialog.dialog_text = "Resett deletes the current track, make sure you've saved your progress!\nThis operation CANNOT BE UNDONE, are you sure you want to reset?"
	# connect signals
	dialog.canceled.connect (dialog_canceled)
	dialog.confirmed.connect (dialog_confirmed)
	
	# show dialog
	add_child(dialog)	
	dialog.popup_centered() # center on screen
	dialog.show()


func dialog_canceled(): 
	print("User clicked Cancel")
	pass
	
func dialog_confirmed(): 
	segments.clear()
	# add initial segment
	add_start = Vector2(0,0)
	var add_end = Vector2( 6,0)
	var seg := Segment.new( add_start, add_end, 0.0 )
	segments.append(seg)
	track_zoom = 15.0
	spin_zoom.value = track_zoom
	track_offset = Vector2( 600, 400 )
	track_name.text = ""
	# redraw
	queue_redraw()	


func _on_spin_zoom_value_changed(value: float) -> void:
	track_zoom = spin_zoom.value
	queue_redraw()


func _on_btn_scale_pressed() -> void:
	for segment in segments:
		segment.length *= 3.0
	queue_redraw()
