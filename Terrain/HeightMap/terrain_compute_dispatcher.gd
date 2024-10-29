extends Node

signal computation_complete

@export_category("Input Textures")
## Noise should be 128 by 128 to match the image size
@export var noise_texture: NoiseTexture2D
## Base should be 128 by 128 to match the image size
@export var base_texture: GradientTexture2D
@export var mix_value: float = 5.0
## If this is changed from 128 by 128, the textures and the relying meshes will need updated
@export var image_size: Vector2i = Vector2i(101, 101)

@export_group("Requirements")
@export_file("*.glsl") var _compute_shader: String
#@export var _renderer: TextureRect

var _rd: RenderingDevice
var _glsl_local_size: Vector3i
var _shader_rid: RID

@onready var _input_output_mappings: Dictionary = {
	"argument_buffer": {
		"rid": null,
		"binding": 0,
	},
	"noise_texture": {
		"rid": null,
		"binding": 1,
	},
	"base_texture": {
		"rid": null,
		"binding": 2,
	},
	"output_texture": {
		"rid": null,
		"binding": 3,
	},
	"output_vector": {
		"rid": null,
		"binding": 4,
	},
}

var _uniform_set_rid : RID
var _bindings: Array[RDUniform] = []


# Accessable outputs
var output_image: Image
var output_vertices: PackedVector3Array


func get_output_vertices() -> PackedVector3Array:
	await computation_complete
	return output_vertices

#region DISPATCH STEPS

func _create_local_rendering_device() -> void:
	_rd = RenderingServer.create_local_rendering_device()
	if not _rd:
		set_process(false)
		printerr("Compute shaders are not available")

func _load_glsl_shader() -> void:
	_glsl_local_size = _get_layout_from_glsl(_compute_shader)
	
	var shader_file: RDShaderFile = load(_compute_shader) as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	_shader_rid = _rd.shader_create_from_spirv(shader_spirv)

func _prepare_argument_input_data() -> void:
	# Include any arguments
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var arguments := PackedFloat32Array([mix_value, image_size.x, image_size.y])
	print("Input: ", arguments)
	var arguments_bytes: PackedByteArray = arguments.to_byte_array()
	
	# Create a storage buffer that can hold our float values.
	_input_output_mappings["argument_buffer"]["rid"] = _rd.storage_buffer_create(arguments_bytes.size(), arguments_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = _input_output_mappings["argument_buffer"]["binding"]
	uniform.add_id(_input_output_mappings["argument_buffer"]["rid"])
	_bindings.append(uniform)

func _create_texture_and_uniform(
	image: Image,
	format: RDTextureFormat,
	binding: int,
) -> RID:
	var view := RDTextureView.new()
	var data: PackedByteArray = image.get_data()
	var texture_id: RID = _rd.texture_create(format, view, [data])
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(texture_id)
	
	_bindings.append(uniform)
	return texture_id

func _texture_format(image: Image, one_byte: bool = false) -> RDTextureFormat:
	var format := RDTextureFormat.new()
	format.width = image.get_size().x
	format.height = image.get_size().y
	# Only really expecting 2 types of format
	format.format = (
		RenderingDevice.DATA_FORMAT_R8_UNORM
		if one_byte else
		RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM 
	)
	format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	return format

func _prepare_texture_uniforms() -> void:
	var noise_image: Image = noise_texture.get_image()
	var noise_input_format: RDTextureFormat = _texture_format(noise_image, true)
	
	var base_image: Image = base_texture.get_image()
	var base_input_format: RDTextureFormat = _texture_format(base_image)
	 
	image_size = noise_image.get_size()
	
	var output_image_buffer := Image.create(
		image_size.x,
		image_size.y,
		false, 
		Image.FORMAT_RGBA8
	)
	var output_format: RDTextureFormat = _texture_format(output_image_buffer)
	
	_input_output_mappings["noise_texture"]["rid"] = _create_texture_and_uniform(
		noise_image, 
		noise_input_format, 
		_input_output_mappings["noise_texture"]["binding"],
	)
	_input_output_mappings["base_texture"]["rid"] = _create_texture_and_uniform(
		base_image,
		base_input_format,
		_input_output_mappings["base_texture"]["binding"],
	)
	_input_output_mappings["output_texture"]["rid"] = _create_texture_and_uniform(
		output_image_buffer,
		output_format,
		_input_output_mappings["output_texture"]["binding"],
	)

func _prepare_vector_array_output_data() -> void:
	var vector_buffer: PackedVector4Array = PackedVector4Array()
	vector_buffer.resize(noise_texture.width * noise_texture.height)
	
	# Create a storage buffer that can hold our vector values.
	var output_bytes: PackedByteArray = vector_buffer.to_byte_array()
	_input_output_mappings["output_vector"]["rid"] =(
		_rd.storage_buffer_create(output_bytes.size(), output_bytes)
	)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = _input_output_mappings["output_vector"]["binding"]
	uniform.add_id(_input_output_mappings["output_vector"]["rid"])
	_bindings.append(uniform)

func _apply_uniforms() -> void:
	var shader_set: int = 0
	_uniform_set_rid = _rd.uniform_set_create(_bindings, _shader_rid, shader_set)

func _create_compute_pipeline() -> void:
	# Create a compute pipeline
	var pipeline: RID = _rd.compute_pipeline_create(_shader_rid)
	var compute_list: int = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	_rd.compute_list_bind_uniform_set(compute_list, _uniform_set_rid, 0)
	var groups_x : int = ceili(float(image_size.x) / float(_glsl_local_size.x))
	var groups_y : int = ceili(float(image_size.y) / float(_glsl_local_size.y))
	print("groups: (", groups_x, ",", groups_y, ")")
	_rd.compute_list_dispatch(compute_list, groups_x, groups_y, _glsl_local_size.z)
	_rd.compute_list_end()

func _submit_to_gpu_and_sync() -> void:
	_rd.submit()
	_rd.sync()

func _extract_input_output_arguments() -> void:
	# Read back the data from the buffer
	var output_bytes : PackedByteArray = (
		_rd.buffer_get_data(_input_output_mappings["argument_buffer"]["rid"])
	)
	var output : PackedFloat32Array = output_bytes.to_float32_array()
	print("Output: ", output, " (arg_id: " , _input_output_mappings["argument_buffer"]["rid"], ")")
	

func _extract_output_data() -> void:
	# Read back the data from the buffers
	var image_bytes : PackedByteArray = _rd.texture_get_data(_input_output_mappings["output_texture"]["rid"], 0)
	output_image = Image.create_from_data(image_size.x, image_size.y, false, Image.FORMAT_RGBA8, image_bytes)
	
	var vector_bytes: PackedByteArray = _rd.buffer_get_data(_input_output_mappings["output_vector"]["rid"], 0)
	var vector_float_array: PackedFloat32Array = vector_bytes.to_float32_array()
	
	output_vertices = PackedVector3Array()
	for i in range(0, len(vector_float_array), 4):
		output_vertices.append(Vector3(vector_float_array[i], vector_float_array[i + 1], vector_float_array[i + 2]))
	
	print(len(output_vertices), " (arg_id: " , _input_output_mappings["output_vector"]["rid"], ")")
	#_renderer.texture = ImageTexture.create_from_image(output_image)

func _clean_up() ->void:
	for mapping in _input_output_mappings:
		_rd.free_rid(_input_output_mappings[mapping]["rid"])
	_rd.free_rid(_shader_rid)

func dispatch() -> void:
	await noise_texture.changed
	_create_local_rendering_device()
	_load_glsl_shader()
	_prepare_argument_input_data()
	_prepare_texture_uniforms()
	_prepare_vector_array_output_data()
	_apply_uniforms()
	_create_compute_pipeline()
	_submit_to_gpu_and_sync()
	_extract_input_output_arguments()
	_extract_output_data()
	computation_complete.emit()
	_clean_up()

#endregion

#region text tools

func _get_layout_from_glsl(path: String) -> Vector3i:
	var regex: RegEx = RegEx.create_from_string(r"layout\(local_size_x\s*=\s*(\d+)\s*,\s*local_size_y\s*=\s*(\d+)\s*,\s*local_size_z\s*=\s*(\d+)\s*\)")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	
	var result: RegExMatch = regex.search(content)
	
	return Vector3i(
		int(result.strings[1]),
		int(result.strings[2]),
		int(result.strings[3]),
	)

#endregion
