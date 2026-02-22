shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size = 1.5;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float alpha = tex.a;

    float outline = 0.0;

    // Sample around the pixel to detect edges
    for (float x = -outline_size; x <= outline_size; x++) {
        for (float y = -outline_size; y <= outline_size; y++) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            outline = max(outline, texture(TEXTURE, UV + offset).a);
        }
    }

    // Draw outline where image is transparent but near opaque pixels
    if (alpha == 0.0 && outline > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = tex;
    }
}