float ramp(float value, float min, float max) {
	float invDiff = 1 / (max - min);
	return clamp(value * invDiff - min * invDiff, 0, 1);
}

float smooth_min(float a, float b, float k) {
	float h = clamp((b - a + k) / (2 * k), 0, 1);
	return a * h + b * ( 1 - h ) - k * h * ( 1 - h );
}

float3 fracHash3(float3 c) {
    float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    return r-0.5;
}
float dotHash(float3 x) {
	float output = dot(x,float3(127.1,311.7, 74.7));
	return frac(sin(output)*43758.5453123);
}
float3 dotHash3( float3 x )
{
	x = float3( dot(x,float3(127.1,311.7, 74.7)),
			  dot(x,float3(269.5,183.3,246.1)),
			  dot(x,float3(113.5,271.9,124.6)));

	return frac(sin(x)*43758.5453123);
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;

float simplex3(float3 p) {
    float3 s = floor(p + dot(p, (float3)F3));
    float3 x = p - s + dot(s, (float3)G3);
	
    float3 e = step((float3)0, x - x.yzx);
    float3 i1 = e*(1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy*(1.0 - e);
	
    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0*G3;
    float3 x3 = x - 1.0 + 3.0*G3;
	
    float4 w, d;
	
    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);
	
    w = max(0.6 - w, 0.0);
	
    d.x = dot(fracHash3(s), x);
    d.y = dot(fracHash3(s + i1), x1);
    d.z = dot(fracHash3(s + i2), x2);
    d.w = dot(fracHash3(s + 1.0), x3);
	
    w *= w;
    w *= w;
    d *= w;
	 
    return dot(d, (float4)52.0);
}

float perlin(float3 p) {
	float3 i = floor(p);
	float3 f = frac(p);
	f = f*f*(3.0-2.0*f);
	
	return 2 * lerp(lerp(lerp(	dotHash(i+float3(0,0,0)), 
								dotHash(i+float3(1,0,0)),f.x),
					lerp(		dotHash(i+float3(0,1,0)), 
								dotHash(i+float3(1,1,0)),f.x),f.y),
					lerp(lerp(	dotHash(i+float3(0,0,1)), 
								dotHash(i+float3(1,0,1)),f.x),
					lerp(		dotHash(i+float3(0,1,1)), 
								dotHash(i+float3(1,1,1)),f.x),f.y),f.z) - 1;
}

float3 voronoi( in float3 x )
{
	float3 p = floor( x );
	float3 f = frac( x );

	float id = 0.0;
	float2 res = 100.0;
	for( int k=-1; k<=1; k++ )
		for( int j=-1; j<=1; j++ )
			for( int i=-1; i<=1; i++ )
			{
				float3 b = float3( float(i), float(j), float(k) );
				float3 r = float3( b ) - f + dotHash3( p + b );
				float d = dot( r, r );

				if( d < res.x )
				{
					id = dot( p+b, float3(1.0,57.0,113.0 ) );
					res = float2( d, res.x );			
				}
				else if( d < res.y )
				{
					res.y = d;
				}
			}

	return float3( sqrt( res ), abs(id) );
}

float cloud_noise(float3 x, int depth, float lacunarity, float dimension) {
	float3 pos = x;
	float noise = 0;
	float amplitude = 0;

	for(int i = 0; i < depth; i++) {
		float divisor = 1 / pow(dimension, i);
		noise += perlin(pow(lacunarity, i) * pos) * divisor;
		amplitude += divisor;
	}
	
	return noise / amplitude;
}

float heterogeneous_musgrave(float3 x, int depth, float lacunarity, float dimension, float offset, float threshold) {
	float spectralExponent = 7 - 2 * dimension;
	float signal = 0.5 * (perlin(x) + offset);
	float result = signal;
	float frequency = 1.0;
	for (int octave = depth; octave > 0; octave--) {
		x *= lacunarity;
		frequency *= lacunarity;
		float amplitude = pow(abs(frequency), -spectralExponent);
		float weight = signal / threshold;
		signal = weight * 0.5 * (perlin(x) + offset);
		result += amplitude * signal;
	}
	
	return result;
}

float crater(float3 x, float size, float rimWidth, float rimHeight, float noiseScale, float distortion) {
	float3 simplex = simplex3(noiseScale * x);
	simplex += simplex3(2 * noiseScale * x) / 2;
	float3 crater = voronoi(x + distortion * simplex);

	const float sqrRimWidth = rimWidth * rimWidth;
	float cavity = ramp(crater.x, 0, size);
	float craterShape = sqrRimWidth * cavity * cavity;
	float rimShape = (rimHeight * (cavity - 1) * (cavity - 1) + sqrRimWidth) / sqrRimWidth;
	float floorShape = (dotHash(crater.z));
	floorShape *= floorShape;
	
	return (smooth_min(craterShape, rimShape, 0.1)) - 1;
}

float octaved_craters(float3 x, int depth, float lacunarity, float dimension, float craterSize, float noiseScale, float distortion) {
	if(depth == 0)
		return 0;
	float height = 0;
	for(int i = 0; i < depth; i++) {
		height += crater(pow(abs(lacunarity), i) * x + i * 168, craterSize, 2, 8, noiseScale, distortion) / pow(abs(dimension), i);
	}
	return height;
}