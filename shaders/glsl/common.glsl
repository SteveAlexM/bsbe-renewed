#define hp highp
#define max0(x) max(0.0, x)
#define stre(x) clamp(x, 0.0, 1.0)
#define csmooth(x) x * x * (3.0 - 2.0 * x)
#define rain smoothstep(0.65, 0.2, FOG_CONTROL.x)
#define nfog stre(1.0 - FOG_COLOR.r * 1.5)
#define dfog stre(FOG_COLOR.r - smoothstep(0.3, 1.0, FOG_COLOR.b))

uniform hp float TOTAL_REAL_WORLD_TIME;

float sqr3(float x){ return x * x * x; }
float sqr4(float x){ return x * x * x * x; }
float sqr5(float x){ return x * x * x * x * x; }

float hash(hp float n){ return fract(sin(n) * 43758.5453); }
float noise(hp vec2 pos){
	hp vec2 ip = floor(pos), fp = csmooth(fract(pos));
	hp float n = ip.x + ip.y * 57.0;
	return mix(mix(hash(n), hash(n + 1.0), fp.x), mix(hash(n + 57.0), hash(n + 58.0), fp.x), fp.y);
}
float cmap(hp vec2 pos){
	float tot = 0.0, den = stre(1.0 - rain);
	pos *= 1.6;
	pos.x += TOTAL_REAL_WORLD_TIME * 0.001;
	for(int i = 0; i < 4; i++){
		tot += noise(pos) * den;
		den *= 0.5;
		pos *= 2.0;
		pos.y += pos.y * (0.8 + tot * 0.2);
		pos.x += TOTAL_REAL_WORLD_TIME * 0.15;
	}
	return 1.0 - pow(0.1, max0(1.0 - tot));
}

vec3 tl(vec3 col){
	return mix(col * 0.07739938, pow(0.947867 * col + 0.0521327, vec3(2.4)), step(0.04045, col));
}
vec3 tg(vec3 col){
	return mix(col * 12.92, pow(col, vec3(0.41666667)) * 1.055 - 0.055, step(0.0031308, col));
}
// aces approxmiation https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
vec3 RRTandODTFit(vec3 col){
	vec3 a = col * (col + 0.0245786) - 0.000090537;
	vec3 b = col * (0.983729 * col + 0.4329510) + 0.238081;
	return a / b;
}
vec3 ACESFitted(vec3 col){
	col *= mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);
	col = RRTandODTFit(col);
	col *= mat3(1.60475, -0.53108, -0.07367, -0.10208,  1.10813, -0.00605, -0.00327, -0.07276,  1.07602);
	col = stre(col);
	return col;
}
vec3 colcor(vec3 col){
	col = ACESFitted(col);
	col = tg(col);
	return mix(vec3(length(col)), col, 1.1);
}

vec3 ccc(){
	vec3 cloudc = mix(mix(mix(vec3(0.85, 1.0, 1.1), vec3(0.9, 0.6, 0.3), dfog), vec3(0.2, 0.3, 0.4), nfog), FOG_COLOR.rgb, rain);
	return tl(cloudc);
}
vec3 csc(hp float skyh){
	vec3 skyc = mix(mix(mix(vec3(0.2, 0.52, 0.9), vec3(0.07, 0.16, 0.25), nfog), vec3(0.3, 0.4, 0.5), dfog), FOG_COLOR.rgb, rain);
		skyc = tl(skyc);
	vec3 scc = mix(mix(mix(vec3(0.73, 0.98, 1.15), vec3(1.0, 0.5, 0.4), dfog), vec3(0.2, 0.3, 0.4), nfog), FOG_COLOR.rgb, rain);
		scc = tl(scc);
	return mix(skyc, scc, skyh);
}
vec3 sr(hp vec3 npos){
	hp float hor = max0(sqr4(1.0 - abs(npos.y)) + sqr4(1.0 - length(npos.zy)) * 15.0 * dfog);
	return csc(hor);
}
