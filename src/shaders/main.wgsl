// Forward shader: GPU vertex skinning + stylized neon lighting.
// All per-vertex transform/skinning work happens here on the GPU; the CPU only
// uploads the joint palette + per-object model matrix once per frame.

struct CameraUniforms {
  viewProj: mat4x4<f32>,
  camPos: vec4<f32>, // xyz = world camera position, w unused
};
@group(0) @binding(0) var<uniform> camera: CameraUniforms;

@group(1) @binding(0) var baseColorSampler: sampler;
@group(1) @binding(1) var baseColorTexture: texture_2d<f32>;

struct SkinUniforms {
  jointMatrices: array<mat4x4<f32>, 128>,
};
@group(2) @binding(0) var<uniform> skin: SkinUniforms;

// Per-object model matrix + emissive. For skinned meshes the matrix is the
// movable character root (rigid); for static meshes it is the mesh's own world
// matrix. emissive.rgb is self-illumination (neon towers); .a is unused.
struct ModelUniforms {
  matrix: mat4x4<f32>,
  emissive: vec4<f32>,
};
@group(3) @binding(0) var<uniform> model: ModelUniforms;

struct VertexInput {
  @location(0) position: vec3<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) normal: vec3<f32>,
  @location(3) joints: vec4<u32>,
  @location(4) weights: vec4<f32>,
};

struct VertexOutput {
  @builtin(position) position: vec4<f32>,
  @location(0) uv: vec2<f32>,
  @location(1) normal: vec3<f32>,
  @location(2) worldPos: vec3<f32>,
};

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
  var out: VertexOutput;

  // Linear-blend skinning. The palette is pre-multiplied so this yields the
  // vertex in the character-root local frame.
  var skinMatrix =
    input.weights.x * skin.jointMatrices[input.joints.x] +
    input.weights.y * skin.jointMatrices[input.joints.y] +
    input.weights.z * skin.jointMatrices[input.joints.z] +
    input.weights.w * skin.jointMatrices[input.joints.w];

  // Unskinned (static) geometry uploads zero weights -> fall back to identity.
  let weightSum = input.weights.x + input.weights.y + input.weights.z + input.weights.w;
  if (weightSum < 0.01) {
    skinMatrix = mat4x4<f32>(
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    );
  }

  let localPos = skinMatrix * vec4<f32>(input.position, 1.0);
  let worldPos = model.matrix * localPos;

  let localNormal = skinMatrix * vec4<f32>(input.normal, 0.0);
  let worldNormal = model.matrix * vec4<f32>(localNormal.xyz, 0.0);

  out.position = camera.viewProj * worldPos;
  out.uv = input.uv;
  out.normal = worldNormal.xyz;
  out.worldPos = worldPos.xyz;
  return out;
}

// Stylized "Spider-Verse" neon lighting: cyan key, magenta fill, soft ambient,
// plus a fresnel rim that feeds the bloom pass. HDR output (rgba16float).
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
  let texColor = textureSample(baseColorTexture, baseColorSampler, input.uv);
  let N = normalize(input.normal);
  let V = normalize(camera.camPos.xyz - input.worldPos);

  let ambient = vec3<f32>(0.16) * texColor.rgb;

  let keyDir = normalize(vec3<f32>(0.6, 0.9, 0.4));
  let keyColor = vec3<f32>(0.35, 0.95, 1.0); // cyan
  let key = texColor.rgb * keyColor * max(dot(N, keyDir), 0.0) * 1.0;

  let fillDir = normalize(vec3<f32>(-0.7, 0.35, -0.5));
  let fillColor = vec3<f32>(1.0, 0.2, 0.9); // magenta
  let fill = texColor.rgb * fillColor * max(dot(N, fillDir), 0.0) * 1.0;

  // Warm key from the upper front — a natural highlight that balances the cool
  // cyan cast on the skin and adds dimension.
  let warmDir = normalize(vec3<f32>(0.25, 0.7, 0.65));
  let warmColor = vec3<f32>(1.0, 0.86, 0.66);
  let warm = texColor.rgb * warmColor * max(dot(N, warmDir), 0.0) * 0.95;

  // Fresnel rim — bright edge light that drives the bloom glow.
  let fresnel = pow(1.0 - max(dot(N, V), 0.0), 3.0);
  let rim = mix(keyColor, fillColor, 0.5) * fresnel * 1.4;

  var color = ambient + key + fill + warm + rim;

  // Distance fog for depth (matches the old scene's atmospheric fog).
  let fogColor = vec3<f32>(0.02, 0.02, 0.06);
  let dist = length(camera.camPos.xyz - input.worldPos);
  let fogFactor = clamp((dist - 14.0) / 70.0, 0.0, 1.0);
  color = mix(color, fogColor, fogFactor);

  // Emissive glows through the haze (only ~half-faded by fog) so neon towers
  // stay readable into the distance, then feeds the bloom pass.
  color += model.emissive.rgb * (1.0 - fogFactor * 0.5);

  return vec4<f32>(color, texColor.a);
}
