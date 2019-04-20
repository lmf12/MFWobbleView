precision mediump float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

uniform float Time;

uniform vec2 PointLT;
uniform vec2 PointRT;
uniform vec2 PointRB;
uniform vec2 PointLB;

const float PI = 3.1415926;

float getA(vec2 point1, vec2 point2) {
    return point2.y - point1.y;
}

float getB(vec2 point1, vec2 point2) {
    return point1.x - point2.x;
}

float getC(vec2 point1, vec2 point2) {
    return point2.x * point1.y - point1.x * point2.y;
}

float getT1(vec2 point1, vec2 point2, vec2 point3, float a, float b, float c) {
    float t = -(sqrt((((-point3.y) + 2.0 * point2.y - point1.y) * b + ((-point3.x) + 2.0 * point2.x -point1.x) * a) * c + (pow(point2.y, 2.0) - point1.y * point3.y) * pow(b, 2.0) + ((-point1.x * point3.y) + 2.0 * point2.x * point2.y - point3.x * point1.y) * a * b +(pow(point2.x, 2.0)-point1.x * point3.x) * pow(a, 2.0)) + (point2.y - point1.y) * b + (point2.x - point1.x) * a) / ((point3.y - 2.0 * point2.y + point1.y) * b + (point3.x - 2.0 * point2.x + point1.x) * a);
    return t;
}

float getT2(vec2 point1, vec2 point2, vec2 point3, float a, float b, float c) {
    float t = (sqrt((((-point3.y) + 2.0 * point2.y - point1.y) * b + ((-point3.x) + 2.0 * point2.x - point1.x) * a) * c + (pow(point2.y, 2.0) - point1.y * point3.y) * pow(b, 2.0) + ((-point1.x * point3.y) + 2.0 * point2.x * point2.y - point3.x * point1.y) * a * b + (pow(point2.x, 2.0) - point1.x * point3.x) * pow(a, 2.0)) + (point1.y - point2.y) * b + (point1.x - point2.x) * a) / ((point3.y - 2.0 * point2.y + point1.y) * b + (point3.x - 2.0 * point2.x + point1.x) * a);
    return t;
}

vec2 getPoint(vec2 point1, vec2 point2, vec2 point3, float t) {
    vec2 point = pow(1.0 - t, 2.0) * point1 + 2.0 * t * (1.0 - t) * point2 + pow(t, 2.0) * point3;
    return point;
}

void main (void) {
    
    float time = mod(Time, 2.0);
    
    vec2 center = (PointLT + PointRT + PointRB + PointLB) / 4.0;
    float distanceToCenter = distance(TextureCoordsVarying, center);
    float maxDistance = 0.3;
    
    vec2 maxOffset = vec2(0.04, 0.04) * sin(time * PI);
    vec2 offset = max(maxDistance - distanceToCenter, 0.0) / maxDistance * maxOffset;
    
    vec4 mask = texture2D(Texture, TextureCoordsVarying + offset);
    gl_FragColor = vec4(mask.rgb, 1.0);
}




