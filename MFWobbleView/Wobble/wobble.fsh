precision highp float;

struct Sketch {
    vec2 PointLT;
    vec2 PointRT;
    vec2 PointRB;
    vec2 PointLB;
};

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

uniform float Time;

uniform Sketch sketchs[4];
uniform int SketchCount;

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

bool isPointInside(vec2 point, vec2 point1, vec2 point2) {
    vec2 tmp1 = point - point1;
    vec2 tmp2 = point - point2;
    return tmp1.x * tmp2.x <= 0.0 && tmp1.y * tmp2.y <= 0.0;
}

float getMaxDistance(vec2 point, vec2 point1, vec2 point2, vec2 point3, vec2 center, float a, float b, float c) {
    float T1 = getT1(point1, point2, point3, a, b, c);
    float T2 = getT2(point1, point2, point3, a, b, c);
    
    float resultDistance = -1.0;
    if (T1 >= 0.0 && T1 <= 1.0) {
        vec2 p = getPoint(point1, point2, point3, T1);
        if (isPointInside(point, p, center)) {
            resultDistance = distance(p, center);
        }
    } else if (T2 >= 0.0 && T2 <= 1.0) {
        vec2 p = getPoint(point1, point2, point3, T2);
        if (isPointInside(point, p, center)) {
            resultDistance = distance(p, center);
        }
    }
    return resultDistance;
}

vec2 getOffset(vec2 pointLT, vec2 pointRT, vec2 pointRB, vec2 pointLB, float time, vec2 targetPoint) {
    vec2 center = (pointLT + pointRT + pointRB + pointLB) / 4.0;
    float distanceToCenter = distance(TextureCoordsVarying, center);
    float maxDistance = -1.0;
    
    vec2 centerLeft = (pointLT + pointLB) / 2.0;
    vec2 centerTop = (pointLT + pointRT) / 2.0;
    vec2 centerRight = (pointRT + pointRB) / 2.0;
    vec2 centerBottom = (pointRB + pointLB) / 2.0;
    
    float a = getA(center, targetPoint);
    float b = getB(center, targetPoint);
    float c = getC(center, targetPoint);
    
    int times = 0;
    float resultDistance = -1.0;
    
    while (resultDistance < 0.0 && times < 4) {
        vec2 point1;
        vec2 point2;
        vec2 point3;
        if (times == 0) {
            point1 = centerLeft;
            point2 = pointLT;
            point3 = centerTop;
        } else if (times == 1) {
            point1 = centerTop;
            point2 = pointRT;
            point3 = centerRight;
        } else if (times == 2) {
            point1 = centerRight;
            point2 = pointRB;
            point3 = centerBottom;
        } else if (times == 3) {
            point1 = centerLeft;
            point2 = pointLB;
            point3 = centerBottom;
        }
        resultDistance = getMaxDistance(targetPoint,
                                        point1, point2, point3,
                                        center,
                                        a, b, c);
        if (resultDistance >= 0.0) {
            maxDistance = resultDistance;
        }
        times++;
    }
    
    vec2 offset = vec2(0, 0);
    if (maxDistance > 0.0) {
        vec2 maxOffset = vec2(0.04, 0.04) * sin(time * PI);
        offset = max(maxDistance - distanceToCenter, 0.0) / maxDistance * maxOffset;
    }
    
    return offset;
}

void main (void) {
    float time = mod(Time, 2.0);

    int count = SketchCount > 4 ? 4 : SketchCount;
    int times = 0;
    vec2 offset = vec2(0.0, 0.0);
    while (!any(notEqual(offset, vec2(0.0, 0.0))) && times < count) {
        Sketch sketch = sketchs[times];
        offset = getOffset(sketch.PointLT, sketch.PointRT, sketch.PointRB, sketch.PointLB, time, TextureCoordsVarying);
        times++;
    }
    
    vec4 mask = texture2D(Texture, TextureCoordsVarying + offset);
    gl_FragColor = vec4(mask.rgb, 1.0);
}




