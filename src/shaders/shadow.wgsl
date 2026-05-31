// Projected planar shadow: the same GPU-skinned character vertices, but the
// per-object model matrix flattens them onto the ground (y≈0) along the key
// light direction. Flat dark, alpha-blended onto the scene. Shares the camera
// (group 0), skin palette (group 2), and a shadow model matrix (group 3).

struct CameraUniforms { viewProj: mat4x4<f32>, camPos: vec4<f32> };
@group(0) @binding(0) var<uniform> camera: CameraUniforms;

struct SkinUniforms { jointMatrices: array<mat4x4<f32>, 128> };
@group(2) @binding(0) var<uniform> skin: SkinUniforms;

struct ModelUniforms { matrix: mat4x4<f32>, emissive: vec4<f32> };
@group(3) @binding(0) var<uniform> model: ModelUniforms;

struct VertexInput {
  @location(0) position: vec3<f32>,
  @location(1) uv: vec2<f32>,
  @location(2) normal: vec3<f32>,
  @location(3) joints: vec4<u32>,
  @location(4) weights: vec4<f32>,
};

@vertex
fn vs_main(input: VertexInput) -> @builtin(position) vec4<f32> {
  var skinMatrix =
    input.weights.x * skin.jointMatrices[input.joints.x] +
    input.weights.y * skin.jointMatrices[input.joints.y] +
    input.weights.z * skin.jointMatrices[input.joints.z] +
    input.weights.w * skin.jointMatrices[input.joints.w];
  let weightSum = input.weights.x + input.weights.y + input.weights.z + input.weights.w;
  if (weightSum < 0.01) {
    skinMatrix = mat4x4<f32>(
      1.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    );
  }
  let worldPos = model.matrix * (skinMatrix * vec4<f32>(input.position, 1.0));
  return camera.viewProj * worldPos;
}

@fragment
fn fs_main() -> @location(0) vec4<f32> {
  return vec4<f32>(0.0, 0.0, 0.02, 0.38);
}
