Shader "CoarseFX/Refraction" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	[TextureFadeScroll(0.2)] _BumpMap("Bumpmap", 2D) = "bump" {}

	[HideInInspector] _BumpMap_Strength("Sprite Texture Strength", Vector) = (1,0,0,0)
	[HideInInspector] _BumpMap_Scroll("Sprite Texture Scroll", Vector) = (0,0,0,0)
}
SubShader { 
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
	ZWrite Off
Pass {
	Blend Zero SrcColor, Zero Zero
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	struct vData
	{
		float4 pos	: SV_POSITION;
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		return OUT;
	}
	
	fixed4 frag(vData IN) : COLOR
	{	
		return OutputDither(_Color, IN.pos.xy);
	}
	ENDCG
}
GrabPass { "_GrabTexture_Refraction"}
Pass {
	Cull Off
	Blend One Zero
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	sampler2D _BumpMap;
	fixed4 _BumpMap_ST;

	float4 _BumpMap_Strength;
	float4 _BumpMap_Scroll;

	Texture2D _GrabTexture_Refraction;

	struct vData
	{
						float4 pos	: SV_POSITION;
		noperspective	float2 sUv	: TEXCOORD0;
		noperspective	fixed2 uv	: TEXCOORD1;
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		OUT.sUv = OUT.pos.xy;
		OUT.uv = TRANSFORM_TEX(v.texcoord.xy, _BumpMap) + _BumpMap_Scroll.xy * _Time.x;
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		OUT.sUv = ComputeGrabScreenPos(OUT.pos).xy / OUT.pos.w * _ScreenParams.xy;
		InterpTri(uv)
		return OUT;
	}
	
	fixed4 frag(vData IN) : COLOR
	{	
		float2 bump = (tex2D(_BumpMap, IN.uv).wy * 2.0f - 1.0f) * _BumpMap_Strength.x;
		bump.y *= _ProjectionParams.x;
		float2 uv = bump * _ScreenParams.xy + IN.sUv;
		fixed4 refrCol = _GrabTexture_Refraction.Load(uint3(uv, 0));
		clip(all(refrCol.a == 0.0 && uv > 0.0 && uv < _ScreenParams.xy) ? 1.0 : -1.0);
		return fixed4(refrCol.rgb, 1.0);
	}
	ENDCG
}//Pass ForwardBase
}//SubShader
}//Shader