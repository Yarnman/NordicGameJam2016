Shader "CoarseFX/Polygon Forward Fix" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	_ColorBack ("Back Color", Color) = (0,0,0,0)
	[TextureFadeScroll] _MainTex("Main Texture", 2D) = "white" {}
	_FogIntns("Fog Intensity", Range(0,1)) = 1
	[Space] [Toggle] _Gouraud("Gouraud Shading", Float) = 1
	[Toggle] _Textured("Textured", Float) = 1
	[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Face Cull Mode", Float) = 0
	[Blending] _Blend ("Blending", Float) = 1
	[LightModeDrawer] _Lighting ("Lighting" , Vector) = (1,1,0,0) 

	[HideInInspector] _MainTex_Strength("Sprite Texture Strength", Vector) = (1,0,0,0)
	[HideInInspector] _MainTex_Scroll("Sprite Texture Scroll", Vector) = (0,0,0,0)
	[HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Depth Test", Float) = 4
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1 
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operator", Float) = 0
	[HideInInspector] [Toggle] _ZWrite ("Depth Write", Float) = 0
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	
	CGINCLUDE
	#pragma target 5.0
	#pragma only_renderers d3d11
	#pragma multi_compile _ _GOURAUD_ON


	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	sampler2D _MainTex;
	fixed4 _MainTex_ST;
	float4 _MainTex_Scroll;
	float4 _MainTex_Strength;

	float _Blend;
	float4 _Lighting;
	fixed4 _ColorBack;
	fixed _FogIntns;

	ENDCG
Pass {
	Name "FORWARDBASE"
	Tags { "LightMode"="ForwardBase" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_fwdbase
	#pragma target 5.0
	#pragma only_renderers d3d11

	#define UNITY_PASS_FORWARDBASE

	struct vData
	{
						float4 pos	: SV_POSITION;
		noperspective	fixed2 uv	: TEXCOORD0;
		noperspective fixed3 amb	: TEXCOORD1;
		COARSEFX_FOG_COORD(2)
		COARSEFX_LIGHTMAP_COORD(3)
		noperspective fixed3 dir	: TEXCOORD4;
		COARSEFX_LIGHTING_COORDS(5,6)
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
			OUT.uv = uv;

		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);
		OUT.amb.rgb = color.rgb;

		fixed3 wNorm = UnityObjectToWorldNormal(v.normal);
		COARSEFX_TRANSFER_LIGHTMAP(OUT, v.texcoord1.xy, v.texcoord2.xy)
		OUT.amb.rgb *= AmbientLight(wNorm);

			OUT.dir = dot(_WorldSpaceLightPos0.xyz, wNorm) * _LightColor0.rgb * color.rgb;
			COARSEFX_TRANSFER_LIGHTING(OUT, mul(_Object2World, v.vertex).xyz)

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		InterpTri(uv)
		FacetedTri(amb)
		COARSEFX_INTERP_FOG
		COARSEFX_INTERP_LIGHTMAP
			FacetedTri(dir)
			COARSEFX_INTERP_LIGHTING
		return OUT;
	}
	
	fixed4 frag(vData IN, bool face : SV_IsFrontFace) : SV_TARGET
	{	
		float4 dither = Dither(IN.pos.xy);
		fixed4 tex = tex2D(_MainTex, IN.uv);
			fixed3 light = face ? IN.dir : -IN.dir;
			light *= light.x < 0.0 ? -_ColorBack.rgb : fixed3(1.0, 1.0, 1.0);
			light *= COARSEFX_LIGHT_ATTENUATION(IN);
			light += COARSEFX_SAMPLE_LIGHTMAP(IN) * IN.amb.rgb;
			fixed4 outcol = fixed4(tex.rgb * light, 1.0);
		COARSEFX_APPLY_FOG(IN, outcol);
		return Output(outcol, dither);
	}
	ENDCG
}//Pass ForwardBase  
Pass {
	Name "FORWARDADD"
	Tags { "LightMode"="ForwardAdd" }
	Blend One One

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_fwdadd_fullshadows
	#pragma target 5.0
	#pragma only_renderers d3d11

	#define UNITY_PASS_FORWARDADD

	struct vData
	{
						float4 pos		: SV_POSITION;
		noperspective	fixed2 uv		: TEXCOORD0;
	#if SPOT || POINT || POINT_COOKIE
		noperspective	fixed2  atten	: TEXCOORD1; //TODO GLCORE BUG
	#endif
		noperspective	fixed3 dir		: TEXCOORD2;
		COARSEFX_LIGHTING_COORDS(3,4)
		COARSEFX_FOG_COORD(5)
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
			OUT.uv = uv;

		float3 wPos = mul(_Object2World, v.vertex).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos);

		fixed3 wNorm = UnityObjectToWorldNormal(v.normal);
		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);
		OUT.dir.rgb = color.rgb;
		OUT.dir.rgb *= dot(normalize(UnityWorldSpaceLightDir(wPos)), wNorm) * _LightColor0.rgb;
		#if POINT_COOKIE || POINT || SPOT
			OUT.atten = COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos);
		#endif

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
			InterpTri(uv)

		FacetedTri(dir)
		#if SPOT || POINT || POINT_COOKIE
			FacetedTri(atten)
		#endif
		COARSEFX_INTERP_FOG
		COARSEFX_INTERP_LIGHTING
		return OUT;
	}
	
	fixed4 frag(vData IN, bool face : SV_IsFrontFace) : SV_TARGET
	{
		float4 dither = Dither(IN.pos.xy);
		fixed4 tex = tex2D(_MainTex, IN.uv);
		fixed3 light = face ? IN.dir.rgb : -IN.dir.rgb;
		light *= light.x < 0.0 ? -_ColorBack.rgb : fixed3(1.0, 1.0, 1.0);
		light *= COARSEFX_LIGHT_ATTENUATION(IN);
		#if SPOT || POINT || POINT_COOKIE
			light *= saturate(IN.atten.x);
		#endif
			fixed4 outcol = fixed4(tex.rgb * light, 1.0);
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, fixed3(0.0, 0.0, 0.0));
		return Output(outcol, dither);
	}
	ENDCG
}//Pass ForwardAdd
Pass {
	Name "SHADOWCASTER"
	Tags { "LightMode"="ShadowCaster" }
	Offset 1, 1

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_shadowcaster
	#pragma target 5.0
	#pragma only_renderers d3d11

	struct vData
	{
		V2F_SHADOW_CASTER;
		noperspective	fixed2 uv	: TEXCOORD1;
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		TRANSFER_SHADOW_CASTER_NORMALOFFSET(OUT)
		OUT.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		if (abs(UNITY_MATRIX_P._m00) != abs(UNITY_MATRIX_P._m11))
			OUT.pos = VertexQuantize(OUT.pos);
		#ifdef SHADOWS_CUBE
			InterpTri(vec)
		#elif UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
			InterpTri(hpos)
		#endif
		InterpTri(uv)
		return OUT;
	}


	float4 frag(vData IN) : SV_TARGET
	{
		SHADOW_CASTER_FRAGMENT(IN)
	}
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader