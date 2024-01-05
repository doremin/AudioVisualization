//
//  CircleShader.metal
//  AudioVisualizer
//
//  Created by doremin on 2023/02/02.
//

#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  vector_float4 pos [[position]];
  vector_float4 color;
};

vertex VertexOut vertexShader(unsigned int vid [[vertex_id]],
                              const constant vector_float2 *vertexArray [[buffer(0)]],
                              const constant float *loudnessUniform [[buffer(1)]],
                              const constant float *lineArray[[buffer(2)]]
                              ) {
  vector_float2 currentVertex = vertexArray[vid];
  float circleScaler = loudnessUniform[0];
  VertexOut output;
  
  if (vid < 1081) {
    output.pos = vector_float4(currentVertex.x * circleScaler, currentVertex.y * circleScaler, 0, 1);
    output.color = vector_float4(1, 1, 1, 1);
  } else {
    int circleID = vid - 1081;
    vector_float2 circleVertex;
    
    if (circleID % 3 == 0) {
      circleVertex = vertexArray[circleID];
      float lineScale = 1 + lineArray[circleID / 3];
      output.pos = vector_float4(circleVertex.x * circleScaler * lineScale, circleVertex.y * circleScaler * lineScale, 0, 1);
      output.color = vector_float4(0, 0, 1, 1);
    } else {
      circleVertex = vertexArray[circleID - 1];
      output.pos = vector_float4(circleVertex.x * circleScaler, circleVertex.y * circleScaler, 0, 1);
      output.color = vector_float4(1, 0, 0, 1);
    }
  }
  
  return output;
}

fragment vector_float4 fragmentShader(VertexOut interpolated [[stage_in]]) {
  return interpolated.color;
}
