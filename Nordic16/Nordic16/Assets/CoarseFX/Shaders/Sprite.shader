Shader "Hidden/CoarseFX/Sprite" {
SubShader {
	ZTest [_ZTest]
	ZWrite [_ZWrite]
	Blend [_BlendSrc] [_BlendDst]
	BlendOp [_BlendOp]
	Cull Off
	CGINCLUDE
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma exclude_renderers gles
	#pragma multi_compile_fog
	#pragma multi_compile QUEUE_GEOMETRY QUEUE_ALPHATEST QUEUE_TRANSPARENT QUEUE_OVERLAY

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc" 

	sampler2D _MainTex;
	fixed4 _MainTex_ST;
	float4 _MainTex_TexelSize;
	uniform float4 _MainTex_Strength;

	fixed _FogIntns;
	fixed4 _Blend;
	float4 _Lighting;

	float4x4 _CameraToWorld;

	const static float rSqrt2 = rsqrt(2.0f);
	const static float rSqrt3 = rsqrt(3.0f);
	const static uint3 index = uint3(0, 1, 2);

	bool GetSpriteTransform(float3x3 pos, float3x2 uv, out float2x2 mat, out float2x2 matNorm, out float4 midP, out float2 uvMid, out float mip, out uint3 h)
	{
		float dist = sqDist(uv[1], uv[2]);
		h = sqDist(uv[0], uv[1]) > dist ? index : dist > sqDist(uv[2], uv[0]) ? index.yzx : index.zxy;
		uint2 u = abs(uv[h.y].x - uv[h.z].x) > abs(uv[h.z].x - uv[h.x].x) ? h.yz : h.zx;
		uint2 v = 3 - h - u;

		float2 uvDiff = uv[h.y] - uv[h.x];

		float3 mid	 = pos[h.x] + pos[h.y];
		float3 top	 = mid - pos[u.x] - pos[u.y];
		float3 right = mid - pos[v.x] - pos[v.y];
		midP = VertexQuantize(mul(UNITY_MATRIX_MVP, float4(mid, 1.0f)));

		float2 inScale = float2(length(mul((float3x3)_Object2World, top)), length(mul((float3x3)_Object2World, right)));
		float2 texScale = abs(uvDiff) * midP.w * _MainTex_TexelSize.zw / _ScreenParams.y;
		float outScale = quantpow2(inScale.x / texScale.x * abs(UNITY_MATRIX_P._m11));
		float aspect = quantpow2(inScale.y / inScale.x);
		texScale *= float2(outScale * aspect, outScale);

		float2 rot = round(normalize(mul((float2x3)UNITY_MATRIX_MV, right).xy) * rSqrt2);
		mat = mul(float2x2(-rot.x, rot.yyx), float2x2(texScale.x, 0.0f, 0.0f, texScale.y));
		matNorm = float2x2(-rot.x, rot.y, -rot.yx) * rSqrt3;
		mat[0] *= abs(UNITY_MATRIX_P._m00 / UNITY_MATRIX_P._m11);
		mat[1] *= -_ProjectionParams.x;

		uvMid = (uv[h.x] + uv[h.y]) * 0.5f;
		mip = -log2(outScale * min(1.0f, aspect));

		return uvDiff.y > 0.0f;
	}

	ENDCG
Pass {
	Name "FORWARDBASE"
	Tags { "LightMode"="ForwardBase" }
	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma exclude_renderers gles
	#pragma multi_compile_fwdbase

	#define UNITY_PASS_FORWARDBASE

	struct vData
	{
					  float4 pos	: SV_POSITION;
		noperspective fixed3 uv		: TEXCOORD0;
		noperspective fixed4 amb	: TEXCOORD1;
		noperspective fixed3 dir	: TEXCOORD2;
		COARSEFX_LIGHTING_COORDS(3,4)
		COARSEFX_FOG_COORD(5)
	};

	void Output(vData IN, vData OUT, inout TriangleStream<vData> stream, float2x2 mat, float2x2 matNorm, float4 mid, float2 uvMid, bool last)
	{
		float2 uvDir = sign(last ? IN.uv.xy - uvMid : uvMid - IN.uv.xy);
		OUT.pos.xy = mul(mat, uvDir) + mid.xy;
		OUT.uv.xy = last ? uvMid * 2.0f - IN.uv.xy : IN.uv.xy;
		float3 wNorm = mul((float3x3)_CameraToWorld, float3(mul(matNorm, uvDir), -rSqrt3));
		OUT.amb = IN.amb;
		OUT.amb.rgb *= AmbientLight(wNorm.y) * _Lighting.y + _Lighting.z;
		OUT.dir = IN.dir * saturate(dot(wNorm, _WorldSpaceLightPos0.xyz));
		float4 vPos = float4(mul(unity_CameraInvProjection, float4(OUT.pos.x, OUT.pos.y * _ProjectionParams.x, -OUT.pos.zw)).xyz, 1.0f);
		float3 wPos = mul(_CameraToWorld, vPos).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos)
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = float3(TRANSFORM_TEX(v.texcoord, _MainTex), 0.0f);
		fixed4 color = v.color * _Color * DepthBoundFade(v.vertex); 
		OUT.amb = color;
		OUT.dir = color.rgb * _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_FOG(OUT, mul(UNITY_MATRIX_MVP, v.vertex));
		COARSEFX_TRANSFER_LIGHTING(OUT, mul(_Object2World, v.vertex).xyz)

		return OUT;
	}

	[maxvertexcount(4)]
	void geom(triangle vData IN[3], inout TriangleStream<vData> stream)
	{
		float3x3 posMat = float3x3(IN[0].pos.xyz, IN[1].pos.xyz, IN[2].pos.xyz); float3x2 uvMat = float3x2(IN[0].uv.xy, IN[1].uv.xy, IN[2].uv.xy);
		float2x2 mat, matNorm; float4 midP; float2 uvMid; float mip; uint3 h;
		if(GetSpriteTransform(posMat, uvMat, mat, matNorm, midP, uvMid, mip, h))
			return;

		vData OUT = IN[0];
		#if OG_LINEAR || FOG_EXP || FOG_EXP2
			OUT.fogCoord = (IN[0].fogCoord + IN[1].fogCoord + IN[2].fogCoord) / 3.0f;
		#endif
		OUT.pos.zw = midP.zw;
		OUT.uv.z = mip;

		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.x], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.y], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, true);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 tex = tex2Dlod(_MainTex, IN.uv.xyzz);
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - 1.0f + IN.amb.a);
		#endif
		tex.rgb = tex.rgb * _MainTex_Strength.x + _MainTex_Strength.y;
		IN.amb.rgb += IN.dir * COARSEFX_LIGHT_ATTENUATION(IN);
		fixed4 outcol = tex * IN.amb;
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, unity_FogColor.rgb * _Blend.x);
		outcol = OutputDither(outcol, IN.pos.xy);
		#ifdef QUEUE_TRANSPARENT
			outcol.rgb *= outcol.a;
			outcol.a *= _Blend.x;
		#endif
		return outcol;
	}
	ENDCG
}//Pass ForwardBase
Pass {
	Name "FORWARDADD"
	Tags { "LightMode"="ForwardAdd" }
	Blend One One, Zero One
	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma exclude_renderers gles
	#pragma multi_compile_fwdadd_fullshadows

	#define UNITY_PASS_FORWARDADD

	struct vData
	{
		float4 pos					: SV_POSITION;
		noperspective fixed3 uv		: TEXCOORD0;
		noperspective fixed4 dir	: TEXCOORD1;
		COARSEFX_LIGHTING_COORDS(2,3)
		COARSEFX_FOG_COORD(4)
	};

	void Output(vData IN, vData OUT, inout TriangleStream<vData> stream, float2x2 mat, float2x2 matNorm, float4 mid, float2 uvMid, bool last)
	{
		float2 uvDir = sign(last ? IN.uv.xy - uvMid : uvMid - IN.uv.xy);
		OUT.uv.xy = last ? uvMid * 2.0f - IN.uv.xy : IN.uv.xy;
		OUT.pos.xy = mul(mat, uvDir) + mid.xy;
		OUT.dir = IN.dir;
		float4 vPos = float4(mul(unity_CameraInvProjection, float4(OUT.pos.x, OUT.pos.y * _ProjectionParams.x, -OUT.pos.zw)).xyz, 1.0f);
		float3 wPos = mul(_CameraToWorld, vPos).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos)
		#if POINT_COOKIE || POINT || SPOT
			OUT.dir.rgb *= COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos);
		#else
			float3 wNorm = mul((float3x3)_CameraToWorld, float3(mul(matNorm, uvDir), -rSqrt3));
			OUT.dir.rgb *= saturate(dot(_WorldSpaceLightPos0.xyz, wNorm));
		#endif
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = float3(TRANSFORM_TEX(v.texcoord, _MainTex), 0.0f);
		fixed4 color = v.color * _Color * DepthBoundFade(v.vertex);
		OUT.dir = color;
		OUT.dir.rgb *= _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_FOG(OUT, v.vertex);
		COARSEFX_TRANSFER_LIGHTING(OUT, v.vertex.xyz)

		return OUT;
	}

	[maxvertexcount(4)]
	void geom(triangle vData IN[3], inout TriangleStream<vData> stream)
	{
		float3x3 posMat = float3x3(IN[0].pos.xyz, IN[1].pos.xyz, IN[2].pos.xyz); float3x2 uvMat = float3x2(IN[0].uv.xy, IN[1].uv.xy, IN[2].uv.xy);
		float2x2 mat, matNorm; float4 midP; float2 uvMid; float mip; uint3 h;
		if(GetSpriteTransform(posMat, uvMat, mat, matNorm, midP, uvMid, mip, h))
			return;

		vData OUT = IN[0];
		#if OG_LINEAR || FOG_EXP || FOG_EXP2
			OUT.fogCoord = (IN[0].fogCoord + IN[1].fogCoord + IN[2].fogCoord) / 3.0f;
		#endif
		OUT.pos.zw = midP.zw;
		OUT.uv.z = mip;

		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.x], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.y], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, true);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 tex = tex2Dlod(_MainTex, IN.uv.xyzz);
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - 1.0f + IN.dir.a);
		#endif
		tex.rgb = tex.rgb * _MainTex_Strength.x + _MainTex_Strength.y;
		fixed4 outcol = tex * IN.dir * COARSEFX_LIGHT_ATTENUATION(IN);
		COARSEFX_APPLY_FOG(IN, outcol.rgb);
		outcol = OutputDither(outcol, IN.pos.xy);
		#ifdef QUEUE_TRANSPARENT
			outcol.rgb *= outcol.a;
		#elif QUEUE_ALPHATEST
			outcol.a = 1.0;
		#endif
		return outcol;
	}
	ENDCG
}//Pass ForwardAdd
Pass {
	Name "VERTEX"
	Tags { "LightMode"="Vertex" }
	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma exclude_renderers gles

	struct vData
	{
					  float4 pos		: SV_POSITION;
		noperspective fixed3 uv		: TEXCOORD0;
		noperspective fixed4 color	: TEXCOORD1;
		COARSEFX_FOG_COORD(2)
	};

	void Output(vData IN, vData OUT, inout TriangleStream<vData> stream, float2x2 mat, float2x2 matNorm, float4 mid, float2 uvMid, bool last)
	{
		float2 uvDir = sign(last ? IN.uv.xy - uvMid : uvMid - IN.uv.xy);
		OUT.uv.xy = last ? uvMid * 2.0f - IN.uv.xy : IN.uv.xy;
		OUT.pos.xy = mul(mat, uvDir) + mid.xy;
		OUT.color = IN.color;
		float3 pos = mul(unity_CameraInvProjection, float4(OUT.pos.x, OUT.pos.y * _ProjectionParams.x, OUT.pos.zw)).xyz;
		float3 norm = float3(mul(matNorm, uvDir), rSqrt3);
		OUT.color.rgb *= VertexLightTransparentMixed(pos, norm, dot(_CameraToWorld[1].xyz, norm), _Lighting);
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		float dbFade = DepthBoundFade(v.vertex);

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = float3(TRANSFORM_TEX(v.texcoord, _MainTex), 0.0f);
		OUT.color = v.color * _Color * dbFade;
		COARSEFX_TRANSFER_FOG(OUT, mul(UNITY_MATRIX_MVP, OUT.pos));

		return OUT;
	}

	[maxvertexcount(4)]
	void geom(triangle vData IN[3], inout TriangleStream<vData> stream)
	{ 
		float3x3 posMat = float3x3(IN[0].pos.xyz, IN[1].pos.xyz, IN[2].pos.xyz); float3x2 uvMat = float3x2(IN[0].uv.xy, IN[1].uv.xy, IN[2].uv.xy);
		float2x2 mat, matNorm; float4 midP; float2 uvMid; float mip; uint3 h;
		if(GetSpriteTransform(posMat, uvMat, mat, matNorm, midP, uvMid, mip, h))
			return;

		vData OUT = IN[0];
		#if OG_LINEAR || FOG_EXP || FOG_EXP2
			OUT.fogCoord = (IN[0].fogCoord + IN[1].fogCoord + IN[2].fogCoord) / 3.0f;
		#endif
		OUT.pos.zw = midP.zw;
		OUT.uv.z = mip;

		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.x], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.y], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, true);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 tex = tex2Dlod(_MainTex, IN.uv.xyzz);
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - 1.0f + IN.color.a);
		#endif
		tex.rgb = tex.rgb * _MainTex_Strength.x + _MainTex_Strength.y;
		fixed4 outcol = tex * IN.color;
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, unity_FogColor.rgb * _Blend.x);
		outcol = OutputDither(outcol, IN.pos.xy);
		#ifdef QUEUE_TRANSPARENT
			outcol.rgb = outcol.rgb * (outcol.a * _Blend.y + _Blend.z) + outcol.a * _Blend.w + _Blend.z;
			outcol.a *= _Blend.x;
		#elif QUEUE_ALPHATEST
			outcol.a = 1.0;
		#endif
		return outcol;
	}
	ENDCG
}//Pass Vertex
Pass {
	Blend Off
	ZWrite On
	Name "SHADOWCASTER"
	Tags { "LightMode"="ShadowCaster" }

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma geometry geom
	#pragma exclude_renderers gles
	#pragma multi_compile_shadowcaster

	struct vData
	{
		V2F_SHADOW_CASTER;
		noperspective fixed3 uv		: TEXCOORD1;
		noperspective fixed2 alpha	: TEXCOORD2;//TODO GLCORE BUG
	};

	void Output(vData IN, vData OUT, inout TriangleStream<vData> stream, float2x2 mat, float2x2 matNorm, float4 mid, float2 uvMid, bool last)
	{
		float2 uvDir = sign(last ? IN.uv.xy - uvMid : uvMid - IN.uv.xy);
		OUT.uv.xy = last ? uvMid * 2.0f - IN.uv.xy : IN.uv.xy;
		OUT.pos.xy = mul(mat, uvDir) + mid.xy;
		OUT.alpha = IN.alpha;
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		TRANSFER_SHADOW_CASTER(OUT)

		OUT.uv = float3(TRANSFORM_TEX(v.texcoord.xy, _MainTex), 0.0f);
		OUT.alpha = 1.0 - v.color.a * _Color.a;

		OUT.pos = v.vertex * 0.5f;

		return OUT; 
	}

	[maxvertexcount(4)]
	void geom(triangle vData IN[3], inout TriangleStream<vData> stream)
	{
		float3x3 posMat = float3x3(IN[0].pos.xyz, IN[1].pos.xyz, IN[2].pos.xyz); float3x2 uvMat = float3x2(IN[0].uv.xy, IN[1].uv.xy, IN[2].uv.xy);
		float2x2 mat, matNorm; float4 midP; float2 uvMid; float mip; uint3 h;
		if(GetSpriteTransform(posMat, uvMat, mat, matNorm, midP, uvMid, mip, h))
			return;

		vData OUT = IN[0]; 
		OUT.pos.zw = midP.zw;
		OUT.uv.z = mip;

		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.x], OUT, stream, mat, matNorm, midP, uvMid, false);
		Output(IN[h.y], OUT, stream, mat, matNorm, midP, uvMid, false); 
		Output(IN[h.z], OUT, stream, mat, matNorm, midP, uvMid, true);
	}

	float4 frag(vData IN) : COLOR
	{
		#ifdef QUEUE_TRANSPARENT
		clip(tex2Dlod(_MainTex, IN.uv.xyzz).a - IN.alpha.x - Dither(IN.pos.xy).a);
		#elif QUEUE_ALPHATEST
		clip(tex2Dlod(_MainTex, IN.uv.xyzz).a - IN.alpha.x);
		#endif
		SHADOW_CASTER_FRAGMENT(IN)
	} 
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader