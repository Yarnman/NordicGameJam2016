Shader "Hidden/CoarseFX/Particle Point" {
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

	fixed _FogIntns;
	fixed4 _Blend;
	float4 _Lighting;

	float4x4 _CameraToWorld;

	const static uint3 index = uint3(0, 1, 2);

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

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = v.texcoord;
		fixed4 color = v.color * _Color * DepthBoundFade(v.vertex);
		OUT.amb = color;
		OUT.dir = color.rgb * _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_LIGHTING(OUT, mul(_Object2World, v.vertex).xyz)
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	[maxvertexcount(1)]
	void geom(triangle vData IN[3], inout PointStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint2 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index.xy : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yz : index.zx;

		if (IN[h.x].uv.x < IN[h.y].uv.x)
			return;

		vData OUT;
		float4 pos = IN[h.x].pos + IN[h.y].pos;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = 0.0f;
		OUT.amb = (IN[0].amb + IN[1].amb + IN[2].amb) / 3.0f;
		OUT.dir = (IN[0].dir + IN[1].dir + IN[2].dir) / 3.0f;
		pos = mul(UNITY_MATRIX_MV, pos);
		float3 norm = normalize(-pos);
		float3 wNorm = mul((float3x3)_CameraToWorld, norm);
		OUT.amb.rgb *= AmbientLight(wNorm.y) * _Lighting.y + _Lighting.z;
		OUT.dir *= saturate(dot(wNorm, _WorldSpaceLightPos0.xyz)) * _Lighting.x;
		COARSEFX_TRANSFER_LIGHTING(OUT, mul(_CameraToWorld, pos).xyz)
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	fixed4 frag(vData IN) : SV_Target
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
}//Pass ForwardBase
Pass {
	Name "FORWARDADD"
	Tags { "LightMode"="ForwardAdd" }
	Blend One One, One OneMinusSrcAlpha

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

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = v.texcoord;
		OUT.dir = v.color * _Color * DepthBoundFade(v.vertex);
		OUT.dir.rgb *= _LightColor0.rgb * _Lighting.x;
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		COARSEFX_TRANSFER_LIGHTING(OUT, v.vertex.xyz)

		return OUT;
	}

	[maxvertexcount(1)]
	void geom(triangle vData IN[3], inout PointStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint2 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index.xy : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yz : index.zx;

		if (IN[h.x].uv.x < IN[h.y].uv.x)
			return;

		vData OUT;
		float4 pos = IN[h.x].pos + IN[h.y].pos;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = 0.0f;
		OUT.dir = (IN[0].dir + IN[1].dir + IN[2].dir) / 3.0f;
		pos = mul(UNITY_MATRIX_MV, pos);
		float3 wPos = mul(_CameraToWorld, pos).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos)
		#if POINT_COOKIE || POINT || SPOT
			OUT.dir.rgb *= COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos) * _Lighting.x;
		#else
			float3 wNorm = mul((float3x3)_CameraToWorld, normalize(-pos));
			OUT.dir.rgb *= saturate(dot(_WorldSpaceLightPos0.xyz, wNorm)) * _Lighting.x;
		#endif

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	fixed4 frag(vData IN) : SV_Target
	{
		fixed4 outcol = IN.dir * COARSEFX_LIGHT_ATTENUATION(IN);
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, fixed3(0.0, 0.0, 0.0));
		outcol = OutputDither(outcol, IN.pos);
		outcol.rgb *= outcol.a;
		return outcol;
	}
	ENDCG
}//Pass ForwardAdd
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

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex * 0.5f;
		OUT.uv = v.texcoord;
		OUT.color = v.color * _Color;
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	[maxvertexcount(1)]
	void geom(triangle vData IN[3], inout PointStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint2 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index.xy : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yz : index.zx;

		if (IN[h.x].uv.x < IN[h.y].uv.x)
			return;

		vData OUT = IN[0];//TODO GLCORE BUG
		float4 pos = IN[h.x].pos + IN[h.y].pos;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = 0.0f;
		pos = mul(UNITY_MATRIX_MV, pos);
		OUT.color = (IN[0].color + IN[1].color + IN[2].color) / 3.0f;
		float3 norm = normalize(-pos);
		OUT.color.rgb *= VertexLightTransparentMixed(pos, norm, dot(_CameraToWorld[1], norm), _Lighting);
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		stream.Append(OUT);
	}

	fixed4 frag(vData IN) : SV_Target
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
		noperspective fixed2 uv	: TEXCOORD1;
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		COARSEFX_TRANSFER_SHADOW_CASTER(v.vertex, OUT)
		OUT.pos = v.vertex * 0.5f;
		OUT.uv = v.texcoord;

		return OUT;
	}

	[maxvertexcount(1)]
	void geom(triangle vData IN[3], inout PointStream<vData> stream)
	{
		float dist = sqDist(IN[1].uv, IN[2].uv);
		uint2 h = sqDist(IN[0].uv, IN[1].uv) > dist ? index.xy : dist > sqDist(IN[2].uv, IN[0].uv) ? index.yz : index.zx;

		if (IN[h.x].uv.x < IN[h.y].uv.x)
			return;

		vData OUT;
		COARSEFX_TRANSFER_SHADOW_CASTER(IN[h.x].pos + IN[h.y].pos, OUT)
		OUT.uv = 0.0f;
		stream.Append(OUT);
	}

	float4 frag(vData IN) : SV_Target
	{
		SHADOW_CASTER_FRAGMENT(IN)
	}
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader