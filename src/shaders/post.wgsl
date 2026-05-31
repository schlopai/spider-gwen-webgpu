// Post-processing: "Into the Spider-Verse" comic look.
//   chromatic aberration -> bloom -> ACES tonemap -> ink edges -> halftone dots
//   -> posterize -> vignette -> animated film grain.
// Keeps the bloom that (with the main shader's fresnel rim) makes the character glow.

@group(0) @binding(0) var screenSampler: sampler;
@group(0) @binding(1) var screenTexture: texture_2d<f32>;

struct Post { time: f32, focusDist: f32, p1: f32, p2: f32 };
@group(0) @binding(2) var<uniform> post: Post;
@group(0) @binding(3) var depthTex: texture_depth_2d;

struct VertexOutput {
  @builtin(position) position: vec4<f32>,
  @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) VertexIndex: u32) -> VertexOutput {
  var pos = array<vec2<f32>, 3>(vec2<f32>(-1.0, -1.0), vec2<f32>(3.0, -1.0), vec2<f32>(-1.0, 3.0));
  var uv = array<vec2<f32>, 3>(vec2<f32>(0.0, 1.0), vec2<f32>(2.0, 1.0), vec2<f32>(0.0, -1.0));
  var out: VertexOutput;
  out.position = vec4<f32>(pos[VertexIndex], 0.0, 1.0);
  out.uv = uv[VertexIndex];
  return out;
}

fn luma(c: vec3<f32>) -> f32 { return dot(c, vec3<f32>(0.299, 0.587, 0.114)); }
fn hash(p: vec2<f32>) -> f32 { return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453); }

fn aces(x: vec3<f32>) -> vec3<f32> {
  let a = 2.51; let b = 0.03; let c = 2.43; let d = 0.59; let e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), vec3<f32>(0.0), vec3<f32>(1.0));
}

@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
  let texSize = vec2<f32>(textureDimensions(screenTexture));
  let px = 1.0 / texSize;
  let uv = input.uv;
  let center = uv - vec2<f32>(0.5);
  let dist = length(center);

  // Chromatic aberration — radial RGB split. dist^2 keeps the centre clean and
  // ramps the split up hard toward the rounded edges/corners.
  let ca = center * (0.0012 + 0.04 * dist * dist);
  var col: vec3<f32>;
  col.r = textureSample(screenTexture, screenSampler, uv + ca).r;
  col.g = textureSample(screenTexture, screenSampler, uv).g;
  col.b = textureSample(screenTexture, screenSampler, uv - ca).b;

  // Depth of field — blur grows with distance from the focal plane (the camera
  // target / character; focus distance comes from the renderer). Auto-sharp at
  // the character, bokeh on the neon skyline.
  let zndc = textureLoad(depthTex, vec2<i32>(clamp(uv * texSize, vec2<f32>(0.0), texSize - vec2<f32>(1.0))), 0);
  let near = 0.1;
  let far = 1000.0;
  let linD = (near * far) / (far - zndc * (far - near));
  let coc = clamp(abs(linD - post.focusDist) / 9.0, 0.0, 1.0);
  if (coc > 0.02) {
    var disk = array<vec2<f32>, 12>(
      vec2<f32>(0.0, 1.0), vec2<f32>(0.87, 0.5), vec2<f32>(0.87, -0.5),
      vec2<f32>(0.0, -1.0), vec2<f32>(-0.87, -0.5), vec2<f32>(-0.87, 0.5),
      vec2<f32>(0.0, 0.5), vec2<f32>(0.43, 0.25), vec2<f32>(0.43, -0.25),
      vec2<f32>(0.0, -0.5), vec2<f32>(-0.43, -0.25), vec2<f32>(-0.43, 0.25)
    );
    let rad = coc * 11.0;
    var blur = vec3<f32>(0.0);
    for (var i = 0u; i < 12u; i = i + 1u) {
      blur = blur + textureSampleLevel(screenTexture, screenSampler, uv + disk[i] * rad * px, 0.0).rgb;
    }
    col = mix(col, blur / 12.0, coc);
  }

  // Bloom — bright-pass neighbour blur (drives the character glow + neon towers).
  var bloom = vec3<f32>(0.0);
  let offsets = array<vec2<f32>, 9>(
    vec2<f32>(-1.0, -1.0), vec2<f32>(0.0, -1.0), vec2<f32>(1.0, -1.0),
    vec2<f32>(-1.0, 0.0), vec2<f32>(0.0, 0.0), vec2<f32>(1.0, 0.0),
    vec2<f32>(-1.0, 1.0), vec2<f32>(0.0, 1.0), vec2<f32>(1.0, 1.0)
  );
  for (var i = 0u; i < 9u; i = i + 1u) {
    let s = textureSample(screenTexture, screenSampler, uv + offsets[i] * px * 5.0).rgb;
    let l = luma(s);
    if (l > 0.6) { bloom = bloom + s * (l - 0.6); }
  }
  bloom = bloom / 9.0;

  var ldr = aces(col + bloom * 2.0);

  // Vignette.
  let vig = 1.0 - smoothstep(0.45, 0.9, dist);
  ldr = ldr * mix(0.6, 1.0, vig);

  // Subtle animated film grain (kept light so skin stays clean).
  let g = hash(uv * texSize + vec2<f32>(post.time, post.time * 1.37)) - 0.5;
  ldr = ldr + vec3<f32>(g * 0.02);

  return vec4<f32>(clamp(ldr, vec3<f32>(0.0), vec3<f32>(1.0)), 1.0);
}
