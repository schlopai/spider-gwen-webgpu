// GPU skeletal pipeline. Three passes; the CPU only uploads per-node TRS.
//   compose:   local[i]  = TRS(trs[i])
//   hierarchy: world[i]  = local[root]*...*local[parent]*local[i]   (ancestor walk)
//   palette:   palette[j] = invMeshWorld * world[jointNode[j]] * invBind[j]
// trans/rot/scale are packed into one buffer (3 vec4 per node) to stay within
// the default maxStorageBuffersPerShaderStage (8). One shared bind group.

struct Params {
  invMeshWorld: mat4x4<f32>,
  nodeCount: u32,
  jointCount: u32,
  pad0: u32,
  pad1: u32,
};

// Per node: [0]=translation.xyz, [1]=rotation.xyzw, [2]=scale.xyz
@group(0) @binding(0) var<storage, read> trs: array<vec4<f32>>;
@group(0) @binding(1) var<storage, read> parent: array<i32>;
@group(0) @binding(2) var<storage, read_write> localM: array<mat4x4<f32>>;
@group(0) @binding(3) var<storage, read_write> worldM: array<mat4x4<f32>>;
@group(0) @binding(4) var<storage, read> jointNode: array<i32>;
@group(0) @binding(5) var<storage, read> invBind: array<mat4x4<f32>>;
@group(0) @binding(6) var<storage, read_write> palette: array<mat4x4<f32>>;
@group(0) @binding(7) var<uniform> params: Params;

// Column-major TRS compose, matching gl-matrix fromRotationTranslationScale.
fn composeTRS(t: vec3<f32>, q: vec4<f32>, s: vec3<f32>) -> mat4x4<f32> {
  let x = q.x; let y = q.y; let z = q.z; let w = q.w;
  let x2 = x + x; let y2 = y + y; let z2 = z + z;
  let xx = x * x2; let xy = x * y2; let xz = x * z2;
  let yy = y * y2; let yz = y * z2; let zz = z * z2;
  let wx = w * x2; let wy = w * y2; let wz = w * z2;
  return mat4x4<f32>(
    vec4<f32>((1.0 - (yy + zz)) * s.x, (xy + wz) * s.x, (xz - wy) * s.x, 0.0),
    vec4<f32>((xy - wz) * s.y, (1.0 - (xx + zz)) * s.y, (yz + wx) * s.y, 0.0),
    vec4<f32>((xz + wy) * s.z, (yz - wx) * s.z, (1.0 - (xx + yy)) * s.z, 0.0),
    vec4<f32>(t.x, t.y, t.z, 1.0),
  );
}

@compute @workgroup_size(64)
fn compose(@builtin(global_invocation_id) gid: vec3<u32>) {
  let i = gid.x;
  if (i >= params.nodeCount) { return; }
  let b = i * 3u;
  localM[i] = composeTRS(trs[b].xyz, trs[b + 1u], trs[b + 2u].xyz);
}

@compute @workgroup_size(64)
fn hierarchy(@builtin(global_invocation_id) gid: vec3<u32>) {
  let i = gid.x;
  if (i >= params.nodeCount) { return; }
  var m = localM[i];
  var p = parent[i];
  loop {
    if (p < 0) { break; }
    m = localM[u32(p)] * m;
    p = parent[u32(p)];
  }
  worldM[i] = m;
}

@compute @workgroup_size(64)
fn palette_main(@builtin(global_invocation_id) gid: vec3<u32>) {
  let j = gid.x;
  if (j >= params.jointCount) { return; }
  let ni = u32(jointNode[j]);
  palette[j] = params.invMeshWorld * (worldM[ni] * invBind[j]);
}
