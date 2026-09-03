shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Generates pseudo-random noise for the glitch jitter
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // Start with the normal screen coordinates
    vec2 uv = SCREEN_UV;
    
    // Create a glitch wave offset using time and glitch_amount
    float glitch_offset = sin(uv.y * 50.0 + TIME * 15.0) * 0.03 * glitch_amount;
    
    // Add random noise jitter
    float jitter = (random(uv + vec2(TIME, 0.0)) - 0.5) * 0.05 * glitch_amount;
    
    // Apply the distortions to the coordinates
    uv.x += glitch_offset + jitter;
    
    // Read the screen texture with the distorted coordinates
    vec4 screen_color = texture(screen_texture, uv);
    
    // Chromatic aberration (splits red and blue channels)
    float chrom_offset = 0.02 * glitch_amount;
    screen_color.r = texture(screen_texture, vec2(uv.x + chrom_offset, uv.y)).r;
    screen_color.b = texture(screen_texture, vec2(uv.x - chrom_offset, uv.y)).b;
    
    // Apply a bright neon green cyberpunk tint based on progress
    vec4 green_tint = vec4(0.0, 0.9, 0.2, 1.0); 
    vec4 final_color = mix(screen_color, green_tint, progress * 0.8);
    
    // Fade to solid black right at the end to hide the scene swap
    if (progress > 0.8) {
        float black_fade = (progress - 0.8) * 5.0;
        final_color = mix(final_color, vec4(0.0, 0.0, 0.0, 1.0), black_fade);
    }
    
    COLOR = final_color;
}