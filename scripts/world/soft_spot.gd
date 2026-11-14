extends RefCounted
## Shared radial mask: a single textured quad replaces layered antialiased circles.

static var _texture: GradientTexture2D


static func texture() -> Texture2D:
	if _texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0, 0.32, 0.68, 1])
		gradient.colors = PackedColorArray(
			[Color.WHITE, Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.22), Color(1, 1, 1, 0)]
		)
		_texture = GradientTexture2D.new()
		_texture.gradient = gradient
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1, 0.5)
	return _texture
