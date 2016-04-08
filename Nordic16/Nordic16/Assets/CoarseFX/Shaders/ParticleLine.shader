Shader "Hidden/CoarseFX/Particle Line" {
SubShader {
	ZTest [_ZTest]
	ZWrite [_ZWrite]
	Blend [_BlendSrc] [_BlendDst]
	BlendOp [_BlendOp]
	CGINCLUDE
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma multi_compile_fog

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	const static uint3 index = uint3(0, 1, 2);

	fixed _FogIntns;
	fixed4 _Blend;
	float4 _Lighting;

	float4x4 _CameraToWorld;

	float3 ProjOnPlane(float3 vec, float3 plane)
	{
		return normalize(vec - dot(vec, plane) * plane);
	}

	ENDCG
Pass {
	Name "FORWARDBASE"
	Tags { "LightMode"="ForwardBase" }
	Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha

	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma multi_compile_fwdbase

	#define UNITY_PASS_FORWARDBASE

	struct vData
	{
		float4 pos	: SV_POSITION;
		fixed4 uv	: TEXCOORD0;
		fixed4 amb	: TEXCOORD1;
		fixed3 dir	: TEXCOORD2;
		COARSEFX_LIGHTING_COORDS(3,4)
		COARSEFX_FOG_COORD(5)
	};

	void Output(float4 pos, float3 plane, fixed4 amb, fixed3 dir, inout LineStream<vData> stream)
	{
		vData OUT;
		OUT.uv = 0.0f;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.amb = amb;
		OUT.dir = dir;

		pos = mul(UNITY_MATRIX_MV, pos);
		float3 norm = ProjOnPlane(normalize(-pos), plane);
		float3 wNorm = mul((float3x3)_CameraToWorld, norm);
		OUT.amb.rgb *= AmbientLight(wNorm.y) * _Lighting.y + _Lighting.z;
		OUT.dir *= saturate(dot(wNorm, _WorldSpaceLightPos0.xyz)) * _Lighting.x;
		COARSEFX_TRANSFER_LIGHTING(OUT, mul(_CameraToWorld, pos).xyz)
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.uv = v.texcoord;
		fixed4 color = v.color * _Color * DepthBoundFade(v.vertex);
		OUT.amb = color;
		OUT.dir = color.rgb * _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_LIGHTING(OUT, mul(_Object2World, v.vertex).xyz)
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	[maxvertexcount(2)]
	void geom(triangle vData IN[3], inout LineStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint3 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yzx : index.zxy;
		uint2 v = abs(IN[h.y].uv.y - IN[h.z].uv.y) > abs(IN[h.z].uv.y - IN[h.x].uv.y) ? h.yz : h.zx;

		float vDiff = (IN[v.x].uv.x + IN[v.y].uv.x) - (IN[h.x].uv.x + IN[h.y].uv.x);
		if (vDiff < 0.0f)
			return;

		float4 a = (IN[v.x].pos + IN[v.y].pos) * 0.5f;
		float4 b = IN[h.x].pos + IN[h.y].pos - a;
		float3 plane = normalize(a - b);
		fixed4 amb = (IN[0].amb + IN[1].amb + IN[2].amb) / 3.0f;
		fixed3 dir = (IN[0].dir + IN[1].dir + IN[2].dir) / 3.0f;

		Output(a, plane, amb, dir, stream);
		Output(b, plane, amb, dir, stream);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 outcol = IN.amb;
		outcol.rgb += IN.dir * COARSEFX_LIGHT_ATTENUATION(IN);
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, unity_FogColor.rgb * _Blend.x);
		outcol = OutputDither(outcol, IN.pos.xy);
		#ifdef QUEUE_TRANSPARENT
			outcol.rgb *= outcol.a;
			outcol.a *= _Blend.x;
		#endif
		return outcol;
	}
	ENDCG
}//Pass ForwardAdd
Pass {
	Name "FORWARDADD"
	Tags { "LightMode"="ForwardAdd" }
	Blend One One, Zero One

	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma multi_compile_fwdadd_fullshadows

	#define UNITY_PASS_FORWARDADD

	struct vData
	{
		float4 pos		: SV_POSITION;
		fixed4 uv		: TEXCOORD0;
		fixed4 dir		: TEXCOORD1;
		COARSEFX_LIGHTING_COORDS(2,3)
		COARSEFX_FOG_COORD(4)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.uv = v.texcoord;
		OUT.dir = v.color * _Color * DepthBoundFade(v.vertex);
		OUT.dir.rgb *= _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		COARSEFX_TRANSFER_LIGHTING(OUT, v.vertex.xyz)

		return OUT;
	}

	void Output(float4 pos, float3 plane, fixed4 color, inout LineStream<vData> stream)
	{
		vData OUT;
		OUT.uv = 0.0f;
		OUT.dir = color;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);

		pos = mul(UNITY_MATRIX_MV, pos);
		float3 norm = ProjOnPlane(normalize(-pos), plane);
		float3 wPos = mul(_CameraToWorld, pos).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos)
		#if POINT_COOKIE || POINT || SPOT
			OUT.dir.rgb *= COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos) * _Lighting.x;
		#else
			float3 wNorm = mul((float3x3)_CameraToWorld, norm);
			OUT.dir.rgb *= saturate(dot(_WorldSpaceLightPos0.xyz, wNorm)) * _Lighting.x;
		#endif
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	[maxvertexcount(2)]
	void geom(triangle vData IN[3], inout LineStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint3 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yzx : index.zxy;
		uint2 v = abs(IN[h.y].uv.y - IN[h.z].uv.y) > abs(IN[h.z].uv.y - IN[h.x].uv.y) ? h.yz : h.zx;

		float vDiff = (IN[v.x].uv.x + IN[v.y].uv.x) - (IN[h.x].uv.x + IN[h.y].uv.x);
		if (vDiff < 0.0f)
			return;

		float4 a = (IN[v.x].pos + IN[v.y].pos) * 0.5f;
		float4 b = IN[h.x].pos + IN[h.y].pos - a;
		float3 plane = normalize(a - b);
		fixed4 color = (IN[0].dir + IN[1].dir + IN[2].dir) / 3.0f;

		Output(a, plane, color, stream);
		Output(b, plane, color, stream);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 outcol = IN.dir * COARSEFX_LIGHT_ATTENUATION(IN);
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, fixed3(0.0, 0.0, 0.0));
		outcol = OutputDither(outcol, IN.pos);
		outcol.rgb *= outcol.a;
		return outcol;
	}
	ENDCG
}//Pass ForwardBase
Pass {
	Name "VERTEX"
	Tags { "LightMode"="Vertex" }
	Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha

	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag

	struct vData
	{
		float4 pos		: SV_POSITION;
		fixed4 uv		: TEXCOORD0;
		fixed4 color	: COLOR;
		COARSEFX_FOG_COORD(1)
	};

	void Output(float4 pos, vData OUT, float3 plane, inout LineStream<vData> stream)
	{
		OUT.uv = 0.0f;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		pos = mul(UNITY_MATRIX_MV, pos);
		float3 norm = ProjOnPlane(normalize(-pos), plane);
		OUT.color.rgb *= VertexLightTransparentMixed(pos, norm, dot(_CameraToWorld[1].xyz, norm), _Lighting);
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.uv = v.texcoord;
		OUT.color = v.color * _Color;
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	[maxvertexcount(2)]
	void geom(triangle vData IN[3], inout LineStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint3 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yzx : index.zxy;
		uint2 v = abs(IN[h.y].uv.y - IN[h.z].uv.y) > abs(IN[h.z].uv.y - IN[h.x].uv.y) ? h.yz : h.zx;

		float vDiff = (IN[v.x].uv.x + IN[v.y].uv.x) - (IN[h.x].uv.x + IN[h.y].uv.x);
		if (vDiff < 0.0f)
			return;

		float4 a = (IN[v.x].pos + IN[v.y].pos) * 0.5f;
		float4 b = IN[h.x].pos + IN[h.y].pos - a;
		float3 plane = normalize(a - b);
		fixed4 color = (IN[0].color + IN[1].color + IN[2].color) / 3.0f;

		vData OUT = IN[0];//TODO GLCORE BUG
		OUT.color = color;

		Output(a, OUT, plane, stream);
		Output(b, OUT, plane, stream);
	}

	fixed4 frag(vData IN) : SV_TARGET
	{
		fixed4 outcol = IN.color;
		COARSEFX_APPLY_FOG(IN, outcol.rgb);
		outcol = OutputDither(outcol, IN.pos);
		outcol.rgb = outcol.rgb * (outcol.a * _Blend.y + _Blend.z) + outcol.a * _Blend.w + _Blend.z;
		outcol.a *= _Blend.x;
		return outcol;
	}
	ENDCG
}//Pass Vertex
Pass {
	Name "SHADOWCASTER"
	Tags { "LightMode"="ShadowCaster" }

	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma multi_compile_shadowcaster

	struct vData
	{
		V2F_SHADOW_CASTER;
		noperspective fixed2 uv		: TEXCOORD1;
		noperspective fixed2 alpha	: TEXCOORD2;
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.uv = v.texcoord;
		OUT.alpha = v.color.a * _Color.a;
		COARSEFX_TRANSFER_SHADOW_CASTER(v.vertex, OUT)

		OUT.pos = v.vertex;

		return OUT;
	}

	[maxvertexcount(2)]
	void geom(triangle vData IN[3], inout LineStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint3 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yzx : index.zxy;
		uint2 v = abs(IN[h.y].uv.y - IN[h.z].uv.y) > abs(IN[h.z].uv.y - IN[h.x].uv.y) ? h.yz : h.zx;

		float vDiff = (IN[v.x].uv.x + IN[v.y].uv.x) - (IN[h.x].uv.x + IN[h.y].uv.x);
		if (vDiff < 0.0f)
			return;

		vData OUT;
		OUT.uv = 0.0f;
		OUT.alpha = (IN[0].alpha + IN[1].alpha + IN[2].alpha) / 3.0f;

		float4 pos = (IN[v.x].pos + IN[v.y].pos) * 0.5f;
		COARSEFX_TRANSFER_SHADOW_CASTER(pos, OUT)
		stream.Append(OUT);

		COARSEFX_TRANSFER_SHADOW_CASTER(IN[h.x].pos + IN[h.y].pos - pos, OUT)
		stream.Append(OUT);
	}

	float4 frag(vData IN) : SV_TARGET
	{
		clip(IN.alpha.x - Dither(IN.pos.xy).a);
		SHADOW_CASTER_FRAGMENT(IN)
	}
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader