#include "UnityCG.cginc"
#define PHI (sqrt(5)*0.5 + 0.5)
#define sqrt2 1.41421356237


float vmax(float2 v) {
    return max(v.x, v.y);
}

float vmax(float3 v) {
    return max(max(v.x, v.y), v.z);
}

float vmax(float4 v) {
    return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(float2 v) {
    return min(v.x, v.y);
}

float vmin(float3 v) {
    return min(min(v.x, v.y), v.z);
}

float vmin(float4 v) {
    return min(min(v.x, v.y), min(v.z, v.w));
}

float fSphere(float3 p, float r) {
    return length(p) - r;
}
float fBox(float3 p, float3 b) {
    float3 d = abs(p) - b;
    return length(max(d, 0)) + vmax(min(d, (float3)0));
}
float fTorus(float3 p, float smallRadius, float largeRadius) {
    return length(float2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}
float fCylinder(float3 p, float r, float height) {
    float d = length(p.xz) - r;
    d = max(d, abs(p.y) - height);
    return d;
}

static const float3 GDFVectors[19] = 
{
    normalize(float3(1, 0, 0)),
    normalize(float3(0, 1, 0)),
    normalize(float3(0, 0, 1)),

    normalize(float3(1, 1, 1 )),
    normalize(float3(-1, 1, 1)),
    normalize(float3(1, -1, 1)),
    normalize(float3(1, 1, -1)),

    normalize(float3(0, 1, PHI+1)),
    normalize(float3(0, -1, PHI+1)),
    normalize(float3(PHI+1, 0, 1)),
    normalize(float3(-PHI-1, 0, 1)),
    normalize(float3(1, PHI+1, 0)),
    normalize(float3(-1, PHI+1, 0)),

    normalize(float3(0, PHI, 1)),
    normalize(float3(0, -PHI, 1)),
    normalize(float3(1, 0, PHI)),
    normalize(float3(-1, 0, PHI)),
    normalize(float3(PHI, 1, 0)),
    normalize(float3(-PHI, 1, 0))
};
float fGDF(float3 p, float r, float e, int begin, int end) {
    float d = 0;
    for (int i = begin; i <= end; ++i)
        d += pow(abs(dot(p, GDFVectors[i])), e);
    return pow(d, 1/e) - r;
}
float fGDF(float3 p, float r, int begin, int end) {
    float d = 0;
    for (int i = begin; i <= end; ++i)
        d = max(d, abs(dot(p, GDFVectors[i])));
    return d - r;
}
float fOctahedron(float3 p, float r, float e) {
    return fGDF(p, r, e, 3, 6);
}
float fDodecahedron(float3 p, float r, float e) {
    return fGDF(p, r, e, 13, 18);
}
float fIcosahedron(float3 p, float r, float e) {
    return fGDF(p, r, e, 3, 12);
}
float fTruncatedOctahedron(float3 p, float r, float e) {
    return fGDF(p, r, e, 0, 6);
}
float fTruncatedIcosahedron(float3 p, float r, float e) {
    return fGDF(p, r, e, 3, 18);
}
float fOctahedron(float3 p, float r) {
    return fGDF(p, r, 3, 6);
}
float fDodecahedron(float3 p, float r) {
    return fGDF(p, r, 13, 18);
}
float fIcosahedron(float3 p, float r) {
    return fGDF(p, r, 3, 12);
}
float fTruncatedOctahedron(float3 p, float r) {
    return fGDF(p, r, 0, 6);
}
float fTruncatedIcosahedron(float3 p, float r) {
    return fGDF(p, r, 3, 18);
}

//Domain Transformation

float3 pM(inout float3 p, in float3 t) {
    p += t;
    return p;
}
float2 pR(inout float2 p, float a) {
    p = cos(a)*p + sin(a)*float2(p.y, -p.x);
    return p;
}
float2 pR45(inout float2 p) {
    p = (p + float2(p.y, -p.x))*sqrt(0.5);
    return p;
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = (p + halfsize) % size - halfsize;
    return c;
}
float pModMirror1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = (p + halfsize) % size - halfsize;
    p *= (c % 2.0)*2 - 1;
    return c;
}
float pModPolar(inout float2 p, float repetitions) {
    float angle = UNITY_TWO_PI/repetitions;
    float a = atan2(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = (a % angle) - angle/2.;
    p = float2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2)) c = abs(c);
    return c;
}
float pMirrorPolar(inout float2 p, uint repetitions) {
    float angle = UNITY_TWO_PI/repetitions;
    float a = atan2(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = (a % angle) - angle/2.;
    p = float2(cos(a), sin(a))*r;
    
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2)) c = abs(c);
    p *= (c % 2) * 2 - 1;
    
    return c;
}

//Combination

float fOpUnionChamfer(float a, float b, float r) {
    return min(min(a, b), (a - r + b)*sqrt(0.5));
}
float fOpIntersectionChamfer(float a, float b, float r) {
    return max(max(a, b), (a + r + b)*sqrt(0.5));
}
float fOpDifferenceChamfer (float a, float b, float r) {
    return fOpIntersectionChamfer(a, -b, r);
}
float fOpUnionRound(float a, float b, float r) {
    float2 u = max(float2(r - a,r - b), 0);
    return max(r, min (a, b)) - length(u);
}
float fOpIntersectionRound(float a, float b, float r) {
    float2 u = max(float2(r + a,r + b), 0);
    return min(-r, max (a, b)) + length(u);
}
float fOpDifferenceRound (float a, float b, float r) {
    return fOpIntersectionRound(a, -b, r);
}