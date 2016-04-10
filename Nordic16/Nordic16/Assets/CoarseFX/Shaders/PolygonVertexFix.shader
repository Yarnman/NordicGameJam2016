Shader "CoarseFX/Polygon Vertex Fix" {
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
	[HideInInspector] _MainTex_Scroll("Sprite Texture Scroll", Vector) = (1,0,0,0)
	[HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Depth Test", Float) = 4
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1 
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operator", Float) = 0
	[HideInInspector] [Toggle] _ZWrite ("Depth Write", Float) = 0
}
SubShader { 
	Tags { "RenderType"="Opaque" }
	Cull [_CullMode]
	ZTest [_ZTest]
	ZWrite [_ZWrite]
	Blend [_BlendSrc] [_BlendDst]
	BlendOp [_BlendOp] 
	
	CGINCLUDE
	#pragma target 5.0
	#pragma only_renderers d3d11
	#pragma multi_compile_fog
	#pragma multi_compile QUEUE_GEOMETRY QUEUE_ALPHATEST QUEUE_TRANSPARENT QUEUE_OVERLAY

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
	Name "VERTEX"
	Tags { "LightMode"="Vertex" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma target 5.0
	#pragma only_renderers d3d11

	struct vData
	{
						float4 pos	: SV_POSITION;
		noperspective	fixed2 uv	: TEXCOORD0;
	#if QUEUE_TRANSPARENT
		FACETEDINTERP	fixed4 dir	: TEXCOORD1;
	#else
		FACETEDINTERP	fixed3 dir	: TEXCOORD1;
	#endif
		COARSEFX_FOG_COORD(2)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + _MainTex_Scroll.xy * _Time.x;
			OUT.uv = uv;

		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);

		OUT.dir.rgb = color.rgb * VertexLightOpaqueMixed(mul(UNITY_MATRIX_MV, v.vertex), mul((float3x3)UNITY_MATRIX_IT_MV, v.normal), UnityObjectToWorldNormal(v.normal).y, _Lighting.xyz);
		#ifdef QUEUE_TRANSPARENT
			OUT.dir.a = color.a;
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
		COARSEFX_INTERP_FOG
		return OUT;
	}
	
	float4 frag(vData IN) : SV_TARGET
	{	
		float4 dither = Dither(IN.pos);
		fixed4 tex = tex2D(_MainTex, IN.uv);
		#ifdef QUEUE_TRANSPARENT
			float4 outcol = tex * IN.dir;
			outcol.rgb *= outcol.a;
		#else
			float4 outcol = fixed4(tex.rgb * IN.dir.rgb, 1.0);
		#endif
		COARSEFX_APPLY_FOG(IN, outcol);
		return Output(outcol, dither);
	}
	ENDCG
}//Pass Vertex
}//SubShader
}//Shader