// Screen-space HUD quad. The rect (in NDC) is supplied by a uniform so the panel
// can be anchored bottom-right at a fixed pixel size on resize. Drawn as a
// 4-vertex triangle strip over the final image, alpha-blended.

struct Rect { r: vec4<f32> }; // x0, yTop, x1, yBottom  (NDC, y up)
@group(0) @binding(0) var<uniform> rect: Rect;
@group(0) @binding(1) var hudSampler: sampler;
@group(0) @binding(2) var hudTexture: texture_2d<f32>;

struct VOut {
  @builtin(position) pos: vec4<f32>,
  @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) i: u32) -> VOut {
  let xs = array<f32, 4>(rect.r.x, rect.r.x, rect.r.z, rect.r.z);
  let ys = array<f32, 4>(rect.r.y, rect.r.w, rect.r.y, rect.r.w);
  let us = array<f32, 4>(0.0, 0.0, 1.0, 1.0);
  let vs = array<f32, 4>(0.0, 1.0, 0.0, 1.0);
  var o: VOut;
  o.pos = vec4<f32>(xs[i], ys[i], 0.0, 1.0);
  o.uv = vec2<f32>(us[i], vs[i]);
  return o;
}

@fragment
fn fs_main(in: VOut) -> @location(0) vec4<f32> {
  return textureSample(hudTexture, hudSampler, in.uv);
}
