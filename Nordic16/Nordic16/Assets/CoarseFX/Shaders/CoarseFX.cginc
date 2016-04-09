fixed4 _Color;
float _Rotation;
samplerCUBE _SkyCube;

sampler2D _DitherTex;
float4 _DitherTex_TexelSize;
float4 _DitherTex_ScaleOfs;
float4 _ColorQuantize;
float4 _ColorQuantizeInv;
float4 _VertexQuantize;
float4 _PerspCor;
 
#define InterpTri(structId) OUT.structId = IN[0].structId * domPos.x + IN[1].structId * domPos.y + IN[2].structId * domPos.z;
#if _GOURAUD_ON || !SHADER_API_D3D11
#define FacetedTri(structId) InterpTri(structId)
#else
#define FacetedTri(structId) OUT.structId = (IN[0].structId + IN[1].structId + IN[2].structId) / 3.0f;
#endif

#if _GOURAUD_ON || !SHADER_API_D3D11
	#define FACETEDINTERP noperspective
#else
	#define FACETEDINTERP nointerpolation
#endif

struct tDataTri
{
	float TessFactor[3]    : SV_TessFactor;
	float InsideTessFactor : SV_InsideTessFactor;
};

static const float eps32 = 5.96e-08;

fixed  quantceil(fixed  x, fixed  y) { return x - (frac(x * y) - 1.0f) / y; }
fixed2 quantceil(fixed2 x, fixed2 y) { return x - (frac(x * y) - 1.0f) / y; }
fixed3 quantceil(fixed3 x, fixed3 y) { return x - (frac(x * y) - 1.0f) / y; }
fixed4 quantceil(fixed4 x, fixed4 y) { return x - (frac(x * y) - 1.0f) / y; }

fixed  quantround(fixed  x, fixed  y) { return x - (frac(x * y + 0.5) - 0.5) / y; }
fixed2 quantround(fixed2 x, fixed2 y) { return x - (frac(x * y + 0.5) - 0.5) / y; }
fixed3 quantround(fixed3 x, fixed3 y) { return x - (frac(x * y + 0.5) - 0.5) / y; }
fixed4 quantround(fixed4 x, fixed4 y) { return x - (frac(x * y + 0.5) - 0.5) / y; }

fixed  quantfloor(fixed  x, fixed  y) { return x - frac(x * y) / y; }
fixed2 quantfloor(fixed2 x, fixed2 y) { return x - frac(x * y) / y; }
fixed3 quantfloor(fixed3 x, fixed3 y) { return x - frac(x * y) / y; }
fixed4 quantfloor(fixed4 x, fixed4 y) { return x - frac(x * y) / y; }

float sqLength(float2 v) { return dot(v, v); }
float sqLength(float3 v) { return dot(v, v); }
float sqLength(float4 v) { return dot(v, v); }

float invLength(float2 v) { return rsqrt(sqLength(v)); }
float invLength(float3 v) { return rsqrt(sqLength(v)); }
float invLength(float4 v) { return rsqrt(sqLength(v)); }

float sqDist(float2 a, float2 b) { return sqLength(a - b); }
float sqDist(float3 a, float3 b) { return sqLength(a - b); }
float sqDist(float4 a, float4 b) { return sqLength(a - b); }

float invDist(float2 a, float2 b) { return invLength(a - b); }
float invDist(float3 a, float3 b) { return invLength(a - b); }
float invDist(float4 a, float4 b) { return invLength(a - b); }

float  quantpow2(float  x) { return exp2(round(log2(x))); }
float2 quantpow2(float2 x) { return exp2(round(log2(x))); }
float3 quantpow2(float3 x) { return exp2(round(log2(x))); }
float4 quantpow2(float4 x) { return exp2(round(log2(x))); }

float  lin(float  srgb) { return srgb < 0.04045f ? srgb * 0.0773993808f : pow(srgb * 0.947867299f + 0.05213270142f, 2.4f); }
float2 lin(float2 srgb) { return srgb < 0.04045f ? srgb * 0.0773993808f : pow(srgb * 0.947867299f + 0.05213270142f, 2.4f); }
float3 lin(float3 srgb) { return srgb < 0.04045f ? srgb * 0.0773993808f : pow(srgb * 0.947867299f + 0.05213270142f, 2.4f); }
float4 lin(float4 srgb) { return srgb < 0.04045f ? srgb * 0.0773993808f : pow(srgb * 0.947867299f + 0.05213270142f, 2.4f); }

float  srgb(float  lin) { return lin < 0.0031308f ? lin * 12.92f : pow(lin, 0.41666f) * 1.055f - 0.055f; }
float2 srgb(float2 lin) { return lin < 0.0031308f ? lin * 12.92f : pow(lin, 0.41666f) * 1.055f - 0.055f; }
float3 srgb(float3 lin) { return lin < 0.0031308f ? lin * 12.92f : pow(lin, 0.41666f) * 1.055f - 0.055f; }
float4 srgb(float4 lin) { return lin < 0.0031308f ? lin * 12.92f : pow(lin, 0.41666f) * 1.055f - 0.055f; }

float3 ObjectToViewNormal(float3 norm)
{
	return normalize(UNITY_MATRIX_T_MV[0].xyz * norm.x + UNITY_MATRIX_T_MV[1].xyz * norm.y + UNITY_MATRIX_T_MV[2].xyz * norm.z);
}

float4 Dither(float2 pos) { return tex2Dlod(_DitherTex, float4(pos.xy * _DitherTex_ScaleOfs.xy + _DitherTex_ScaleOfs.zw, 0.0f, 0.0f)); }

fixed3 Output(fixed3 col, fixed4 dither)
{
	col = srgb(col) + dither * _ColorQuantizeInv;
	return lin(col - frac(col * _ColorQuantize) * _ColorQuantizeInv);
}
fixed4 Output(fixed4 col, fixed4 dither)
{
	col = srgb(col) + dither * _ColorQuantizeInv;
	return lin(col - frac(col * _ColorQuantize) * _ColorQuantizeInv);
}
fixed3 OutputDither(fixed3 col, float2 pos) { return Output(col, Dither(pos)); }
fixed4 OutputDither(fixed4 col, float2 pos) { return Output(col, Dither(pos)); }

float4 VertexQuantize(float4 pos)
{
	pos.xy /= pos.w;
	pos.y += UNITY_MATRIX_P._m12;
	pos.xy -= (frac(pos.xy * _VertexQuantize.xy + 0.5) - 0.5) * _VertexQuantize.zw;
	pos.y -= UNITY_MATRIX_P._m12;
	pos.xy *= pos.w;
	return pos;
}

float DepthBoundFade(float4 oPos)
{	
	return 1;
	float depth = dot(UNITY_MATRIX_MV[2], oPos);
	return min(-depth - _ProjectionParams.y, 1.0f) * min(depth + _ProjectionParams.z, 1.0f);
}

fixed4 tex2Dpoint(texture2D tex, float2 uv)
{
	float2 res; tex.GetDimensions(res.x, res.y);
	return tex.Load(uint3(uv * res, 0));
}

float PerspectiveCorrect(float4 a, float4 b)
{
	float3 viewA = mul(unity_CameraInvProjection, a).xyz;
	float3 viewB = mul(unity_CameraInvProjection, b).xyz;
	float slope = abs(a.z - b.z) / (abs(a.z) + abs(b.z)) * _PerspCor.x;
	float bias = distance(a, b) / (length(a) + length(b)) * _PerspCor.y;
	return slope + bias + eps32;
} 

#define HULL_PERSPECTIVE_CORRECT tDataTri hullConst(InputPatch<vData, 3> IN) \
{ \
	tDataTri OUT; \
	OUT.TessFactor[0] = PerspectiveCorrect(IN[1].pos, IN[2].pos); \
	OUT.TessFactor[1] = PerspectiveCorrect(IN[2].pos, IN[0].pos); \
	OUT.TessFactor[2] = PerspectiveCorrect(IN[0].pos, IN[1].pos); \
	OUT.InsideTessFactor = (OUT.TessFactor[0] + OUT.TessFactor[1] + OUT.TessFactor[2]) / 3.0f; \
	return OUT; \
} \
[domain("tri")] \
[partitioning("integer")] \
[outputtopology("triangle_cw")] \
[patchconstantfunc("hullConst")] \
[outputcontrolpoints(3)] \
vData hull(InputPatch<vData, 3> IN, int id : SV_OutputControlPointID) \
{ \
	return IN[id]; \
} \
[domain("tri")]

fixed3 AmbientLight(float norm)
{
	return unity_AmbientSky.rgb * saturate(norm) + unity_AmbientEquator.rgb * saturate(1.0f - abs(norm)) + unity_AmbientGround.rgb * saturate(-norm);
}

fixed3 AmbientLight(float3 norm)
{
	#if LIGHTMAP_ON || DYNAMICLIGHTMAP_ON
		return 1.0;
	#else
		#ifdef UNITY_SHOULD_SAMPLE_SH
			return ShadeSH12Order(half4(norm, 1.0));
		#else
			return unity_AmbientSky.rgb * saturate(norm.y) + unity_AmbientEquator.rgb * saturate(1.0f - abs(norm.y)) + unity_AmbientGround.rgb * saturate(-norm.y);
		#endif
	#endif
}

fixed3 VertexLightOpaqueBASE(float3 pos, float3 norm)
{
	fixed3 lightColor = 0.0;
	for (int i = 0; i < 8; i++)
	{
		float3 lDir = unity_LightPosition[i].xyz - pos * unity_LightPosition[i].w;
		float len = length(lDir);
		lDir /= len;

		float atten = saturate(len * -rsqrt(unity_LightAtten[i].w) + 1.0f);
		atten *= saturate((saturate(dot(lDir, unity_SpotDirection[i].xyz)) - unity_LightAtten[i].x) * unity_LightAtten[i].y);
		atten *= saturate(dot(norm, lDir));
		lightColor += unity_LightColor[i].rgb * atten;
	}
	return lightColor;
}

fixed3 VertexLightTransparentBASE(float3 pos, float3 norm)
{
	fixed3 lightColor = 0.0;
	for (uint i = 0; i < 8; i++)
	{
		float3 lDir = unity_LightPosition[i].xyz - pos * unity_LightPosition[i].w;
		float len = dot(lDir, lDir);

		float atten = saturate(1.0f - sqrt(len / unity_LightAtten[i].w));
		atten *= saturate((saturate(dot(lDir, unity_SpotDirection[i].xyz) * rsqrt(len)) - unity_LightAtten[i].x) * unity_LightAtten[i].y);
		atten *= unity_LightPosition[i].w == 0.0f ? saturate(dot(norm, unity_LightPosition[i].xyz)) : 1.0f;
		lightColor += unity_LightColor[i].rgb * atten;
	}
	return lightColor;
}

fixed3 VertexLightOpaque(float3 pos, float3 norm, float wNorm)
{
	return VertexLightOpaqueBASE(pos, norm) + AmbientLight(wNorm);
}

fixed3 VertexLightOpaqueMixed(float3 pos, float3 norm, float wNorm, float3 mix)
{
	return VertexLightOpaqueBASE(pos, norm) * mix.x + AmbientLight(wNorm) * mix.y + mix.z;
}

fixed3 VertexLightTransparent(float3 pos, float3 norm, float wNorm)
{
	return VertexLightOpaqueBASE(pos, norm) + AmbientLight(wNorm);
}

fixed3 VertexLightTransparentMixed(float3 pos, float3 norm, float wNorm, float3 mix)
{
	return VertexLightTransparentBASE(pos, norm) * mix.x + AmbientLight(wNorm) * mix.y + mix.z;
}

#if FOG_LINEAR || FOG_EXP || FOG_EXP2
	#define COARSEFX_FOG_COORD(id) noperspective float2 fogCoord : TEXCOORD##id;
	#define COARSEFX_INTERP_FOG InterpTri(fogCoord);
	#define COARSEFX_TRANSFER_FOG(OUT, pos) UNITY_CALC_FOG_FACTOR(pos.z); OUT.fogCoord = unityFogFactor * _FogIntns + 1.0f - _FogIntns
	#define COARSEFX_APPLY_FOG(IN, col) UNITY_FOG_LERP_COLOR(col, unity_FogColor, IN.fogCoord.x)
	#define COARSEFX_APPLY_FOG_COLOR(IN, col, fogCol) UNITY_FOG_LERP_COLOR(col, fogCol, IN.fogCoord.x)
#else 
	#define COARSEFX_FOG_COORD(id)
	#define COARSEFX_INTERP_FOG
	#define COARSEFX_TRANSFER_FOG(OUT, pos)
	#define COARSEFX_APPLY_FOG(IN, col)
	#define COARSEFX_APPLY_FOG_COLOR(IN, col, fogCol)
#endif

#ifdef SHADOWS_CUBE
	#define COARSEFX_TRANSFER_SHADOW_CASTER(ipos, o) \
		o.pos = mul(UNITY_MATRIX_MVP, float4((ipos).xyz, 1.0f)); \
		o.vec = mul(_Object2World, float4((ipos).xyz, 1.0f)).xyz - _LightPositionRange.xyz;
#else
	#ifdef UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
		#define COARSEFX_TRANSFER_SHADOW_CASTER(ipos, o) \
			o.pos = UnityApplyLinearShadowBias(mul(UNITY_MATRIX_MVP, float4((ipos).xyz, 1.0f))); \
			o.hpos = o.pos;
	#else
		#define COARSEFX_TRANSFER_SHADOW_CASTER(ipos, o) \
			o.pos = UnityApplyLinearShadowBias(mul(UNITY_MATRIX_MVP, float4((ipos).xyz, 1.0f)));
	#endif
#endif

fixed4 _LightColor0;

#if POINT || DIRECTIONAL_COOKIE || SPOT || POINT_COOKIE
	float4x4 _LightMatrix0;
#endif
#if POINT || DIRECTIONAL_COOKIE || SPOT
	sampler2D _LightTexture0;
#elif POINT_COOKIE
	samplerCUBE _LightTexture0;
#endif
#if SPOT || POINT_COOKIE
	sampler2D _LightTextureB0;
#endif

#ifdef SPOT
	#define COARSEFX_SHADOW_COORD(id) noperspective float4 _ShadowCoord : TEXCOORD##id;
	#ifdef SHADOWS_DEPTH
		#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) OUT._ShadowCoord = mul(unity_World2Shadow[0], float4(wPos, 1.0f));
	#else
		#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) OUT._ShadowCoord = mul(_LightMatrix0, float4(wPos, 1.0f));
	#endif
	#define COARSEFX_INTERP_SHADOW_COORD InterpTri(_ShadowCoord)
#elif SHADOWS_SCREEN && UNITY_NO_SCREENSPACE_SHADOWS
	#define COARSEFX_SHADOW_COORD(id) float4 _ShadowCoord : TEXCOORD##id;
	#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) OUT._ShadowCoord = mul(unity_World2Shadow[0], float4(wPos, 1.0f));
	#define COARSEFX_INTERP_SHADOW_COORD InterpTri(_ShadowCoord)
#elif SHADOWS_SCREEN
	#define COARSEFX_SHADOW_COORD(id) float2 _ShadowCoord : TEXCOORD##id;
	#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) OUT._ShadowCoord = ComputeScreenPos(OUT.pos).xy / OUT.pos.w * _ScreenParams.xy;
	#define COARSEFX_INTERP_SHADOW_COORD OUT._ShadowCoord = ComputeScreenPos(OUT.pos).xy / OUT.pos.w * _ScreenParams.xy;
#elif SHADOWS_CUBE
	#define COARSEFX_SHADOW_COORD(id) noperspective float3 _ShadowCoord : TEXCOORD##id;
	#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) OUT._ShadowCoord = wPos - _LightPositionRange.xyz;
	#define COARSEFX_INTERP_SHADOW_COORD InterpTri(_ShadowCoord)
#else
	#define COARSEFX_SHADOW_COORD(id)
	#define COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos)
	#define COARSEFX_INTERP_SHADOW_COORD
#endif

#ifdef POINT_COOKIE
	#define COARSEFX_LIGHT_COORD(id) noperspective float3 _LightCoord : TEXCOORD##id;
	#define COARSEFX_TRANSFER_LIGHT_COORD(OUT, wPos) OUT._LightCoord = OUT._LightCoord = mul(_LightMatrix0, float4(wPos, 1.0f)).xyz;
	#define COARSEFX_INTERP_LIGHT_COORD InterpTri(_LightCoord)
#elif DIRECTIONAL_COOKIE
	#define COARSEFX_LIGHT_COORD(id) noperspective float2 _LightCoord : TEXCOORD##id;	
	#define COARSEFX_TRANSFER_LIGHT_COORD(OUT, wPos) OUT._LightCoord = OUT._LightCoord = mul(_LightMatrix0, float4(wPos, 1.0f)).xy;
	#define COARSEFX_INTERP_LIGHT_COORD InterpTri(_LightCoord)
#else
	#define COARSEFX_LIGHT_COORD(id)
	#define COARSEFX_TRANSFER_LIGHT_COORD(OUT, wPos)
	#define COARSEFX_INTERP_LIGHT_COORD
#endif

#define COARSEFX_LIGHTING_COORDS(id0, id1) COARSEFX_SHADOW_COORD(id0) COARSEFX_LIGHT_COORD(id1)
#define COARSEFX_TRANSFER_LIGHTING(OUT, wPos) COARSEFX_TRANSFER_SHADOW_COORD(OUT, wPos) COARSEFX_TRANSFER_LIGHT_COORD(OUT, wPos) 
#define COARSEFX_INTERP_LIGHTING COARSEFX_INTERP_SHADOW_COORD COARSEFX_INTERP_LIGHT_COORD

#ifdef POINT_COOKIE
	#define COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos) (1.0f - length(OUT._LightCoord.xyz))
#elif POINT || SPOT
	#define COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos) (1.0f - length(mul(_LightMatrix0, float4(wPos, 1.0f)).xyz))
#else
	#define COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos) (1.0f)
#endif

#if SHADOWS_SCREEN && !UNITY_NO_SCREENSPACE_SHADOWS
	Texture2D _ShadowMapTexture;
	#define COARSEFX_SHADOW(IN) _ShadowMapTexture.Load(uint3(IN.pos.xy, 0)).x
#elif SHADOWS_SCREEN
	UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
	#ifdef SHADOWS_NATIVE
		#define COARSEFX_SHADOW(IN) (UNITY_SAMPLE_SHADOW(_ShadowMapTexture, IN._ShadowCoord.xyz) * (1.0 - _LightShadowData.x) + _LightShadowData.x);
	#else
		#define COARSEFX_SHADOW(IN) (SAMPLE_DEPTH_TEXTURE_PROJ(_ShadowMapTexture, IN._ShadowCoord) < IN._ShadowCoord.z / IN._ShadowCoord.w ? _LightShadowData.x : 1.0);
	#endif
#elif SPOT && SHADOWS_DEPTH
	UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
	float4 _ShadowMapTexture_TexelSize;
	#ifdef SHADOWS_NATIVE
		#define COARSEFX_SHADOW(IN) (tex2Dpoint(_ShadowMapTexture, IN._ShadowCoord.xy / IN._ShadowCoord.w).x < IN._ShadowCoord.z / IN._ShadowCoord.w ? _LightShadowData.x : 1.0);
	#else
		#define COARSEFX_SHADOW(IN) (SAMPLE_DEPTH_TEXTURE_PROJ(_ShadowMapTexture, UNITY_PROJ_COORD(IN._ShadowCoord)).x < IN._ShadowCoord.z / IN._ShadowCoord.w ? _LightShadowData.x : 1.0);
	#endif
#elif SHADOWS_CUBE
	uniform samplerCUBE_float _ShadowMapTexture;
	#define COARSEFX_SHADOW(IN) (UnityDecodeCubeShadowDepth(texCUBE(_ShadowMapTexture,  IN._ShadowCoord)) < length(IN._ShadowCoord) * _LightPositionRange.w * 0.97f ? _LightShadowData.x : 1.0)
#else
	#define COARSEFX_SHADOW(IN) 1.0
#endif

#ifdef SPOT
	#ifdef SHADOWS_DEPTH
		#define COARSEFX_LIGHT_ATTENUATION(IN) (IN._ShadowCoord.z > 0.0f) * tex2D(_LightTexture0, IN._ShadowCoord.xy / IN._ShadowCoord.w).a * COARSEFX_SHADOW(IN)
	#else
		#define COARSEFX_LIGHT_ATTENUATION(IN) (IN._ShadowCoord.z > 0.0f) * tex2D(_LightTexture0, IN._ShadowCoord.xy / IN._ShadowCoord.w + 0.5f).a * COARSEFX_SHADOW(IN)
	#endif
#elif POINT_COOKIE
	#define COARSEFX_LIGHT_ATTENUATION(IN) texCUBE(_LightTexture0, IN._LightCoord.xyz).a * COARSEFX_SHADOW(IN)
#elif DIRECTIONAL_COOKIE
	#define COARSEFX_LIGHT_ATTENUATION(IN) (tex2D(_LightTexture0, IN._LightCoord.xy).a * _LightColor0.a + 1.0 - _LightColor0.a) * COARSEFX_SHADOW(IN)
#else
	#define COARSEFX_LIGHT_ATTENUATION(IN) COARSEFX_SHADOW(IN)
#endif

#if LIGHTMAP_ON || DYNAMICLIGHTMAP_ON
	#define COARSEFX_INTERP_LIGHTMAP InterpTri(lmUv)
#else
	#define COARSEFX_INTERP_LIGHTMAP
#endif

#if LIGHTMAP_ON && DYNAMICLIGHTMAP_ON
	#define COARSEFX_LIGHTMAP_COORD(id) noperspective float4 lmUv	: TEXCOORD##id;
	#define COARSEFX_TRANSFER_LIGHTMAP(OUT, coord0, coord1) float4 res; unity_Lightmap.GetDimensions(res.x, res.y); unity_DynamicLightmap.GetDimensions(res.z, res.w); \
	OUT.lmUv = (float4(coord0, coord1) * float4(unity_LightmapST.xy, unity_DynamicLightmapST.xy) + float4(unity_LightmapST.zw, unity_DynamicLightmapST.zw)) * res;
	#define COARSEFX_SAMPLE_LIGHTMAP(IN) (DecodeLightmap(unity_Lightmap.Load(uint3(IN.lmUv.xy, 0))) + DecodeRealtimeLightmap(unity_DynamicLightmap.Load(uint3(IN.lmUv.zw, 0))))
#elif LIGHTMAP_ON
	#define COARSEFX_LIGHTMAP_COORD(id) noperspective float2 lmUv	: TEXCOORD##id;
	#define COARSEFX_TRANSFER_LIGHTMAP(OUT, coord0, coord1) float2 res; unity_Lightmap.GetDimensions(res.x, res.y); \
	OUT.lmUv = (coord0 * unity_LightmapST.xy + unity_LightmapST.zw) * res;
	#define COARSEFX_SAMPLE_LIGHTMAP(IN) DecodeLightmap(unity_Lightmap.Load(uint3(IN.lmUv, 0)))
#elif DYNAMICLIGHTMAP_ON
	#define COARSEFX_LIGHTMAP_COORD(id) noperspective float2 lmUv	: TEXCOORD##id;
	#define COARSEFX_TRANSFER_LIGHTMAP(OUT, coord0, coord1) float2 res; unity_DynamicLightmap.GetDimensions(res.x, res.y); \
	OUT.lmUv = (coord1 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw) * res;
	#define COARSEFX_SAMPLE_LIGHTMAP(IN) DecodeRealtimeLightmap(unity_DynamicLightmap.Load(uint3(IN.lmUv, 0)))
#else
	#define COARSEFX_LIGHTMAP_COORD(id)
	#define COARSEFX_TRANSFER_LIGHTMAP(OUT, coord0, coord1)
	#define COARSEFX_SAMPLE_LIGHTMAP(IN) 1.0
#endif