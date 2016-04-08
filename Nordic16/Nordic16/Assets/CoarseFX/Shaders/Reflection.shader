Shader "CoarseFX/Reflection" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	_Fresnel ("Fresnel", Range(0,5)) = 5
	[TextureFadeScroll(0.1)] _BumpMap("Bumpmap", 2D) = "bump" {}
	//[AdvancedTab] _Advanced("Show Advanced", Float) = 1
	_FogIntns("Fog Intensity", Range(0,1)) = 1
	_AddBlend("Additive/Blended", Range(0,1)) = 1

	[HideInInspector] _BumpMap_Strength("Sprite Texture Strength", Vector) = (1,0,0,0)
	[HideInInspector] _BumpMap_Scroll("Sprite Texture Scroll", Vector) = (0,0,0,0)
}
SubShader { 
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
Pass {
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma multi_compile_fog

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc" 

	float _Fresnel;

	sampler2D _BumpMap;
	fixed4 _BumpMap_ST;

	float4 _BumpMap_Strength;
	float4 _BumpMap_Scroll;

	uniform samplerCUBE coarseFX_SpecCube;
	fixed _FogIntns;

	struct vData
	{
						float4 pos		: SV_POSITION;
		noperspective	fixed2 uv		: TEXCOORD0;
		noperspective	float3 view		: TEXCOORD1;
		COARSEFX_FOG_COORD(2)
	/*nointerpolation*/	float3x3 rot	: TEXCOORD3;//TODO GLCORE BUG
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		OUT.uv = TRANSFORM_TEX(v.texcoord.xy, _BumpMap) + _BumpMap_Scroll.xy * _Time.x;
		TANGENT_SPACE_ROTATION;
		float3 objScale = float3(invLength(_World2Object[0].xyz), invLength(_World2Object[1].xyz), invLength(_World2Object[2].xyz));
		OUT.rot = float3x3(
			normalize(mul(rotation, _Object2World[0].xyz) * objScale),
			normalize(mul(rotation, _Object2World[1].xyz) * objScale),
			normalize(mul(rotation, _Object2World[2].xyz) * objScale));
		OUT.view = -WorldSpaceViewDir(v.vertex);
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
		InterpTri(view)
		InterpTri(rot)
		COARSEFX_INTERP_FOG
		return OUT;
	}
	 
	fixed4 frag(vData IN) : COLOR
	{	
		float3 bump;
		bump.xy = (tex2D(_BumpMap, IN.uv).wy * 2.0f - 1.0f) * _BumpMap_Strength.x;
		bump.z = sqrt(1.0f - saturate(dot(bump.xy, bump.xy)));
		float3 norm = mul(IN.rot, bump);
		IN.view = normalize(IN.view);
		float3 refl = reflect(IN.view, norm);
		float fresnel = pow(saturate(1.0f + dot(IN.view, norm)), _Fresnel);
		fixed3 reflcol = texCUBE(coarseFX_SpecCube, refl).rgb;

		fixed4 outcol = fixed4(reflcol, fresnel) * _Color;
		COARSEFX_APPLY_FOG(IN, outcol);
		return OutputDither(outcol, IN.pos.xy);
	}
	ENDCG
}//Pass ForwardBase
}//SubShader
}//Shader