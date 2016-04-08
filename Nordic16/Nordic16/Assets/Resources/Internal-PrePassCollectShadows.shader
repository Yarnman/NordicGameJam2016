Shader "Hidden/Internal-PrePassCollectShadows" {
Properties {
	_ShadowMapTexture("", any) = "" {}
}
SubShader {
Pass {
	ZWrite Off ZTest Always Cull Off

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile_shadowcollector
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"

	sampler2D _CameraDepthTexture;
	float4 unity_ShadowCascadeScales;

	CBUFFER_START(UnityPerCamera2)
	float4x4 _CameraToWorld;
	CBUFFER_END

	UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
	float4 _ShadowMapTexture_TexelSize;

	#ifdef SHADOWS_SPLIT_SPHERES
		#define GET_CASCADE_WEIGHTS(wpos, z)		getCascadeWeights_splitSpheres(wpos)
		#define GET_SHADOW_FADE(wpos, z)			getShadowFade_SplitSpheres(wpos)
	#else
		#define GET_CASCADE_WEIGHTS(wpos, z)	getCascadeWeights(z)
		#define GET_SHADOW_FADE(wpos, z)		getShadowFade(z)
	#endif

	#ifdef SHADOWS_SINGLE_CASCADE
		#define GET_SHADOW_COORDINATES(wpos,cascadeWeights)	getShadowCoord_SingleCascade(wpos)
	#else
		#define GET_SHADOW_COORDINATES(wpos,cascadeWeights)	getShadowCoord(wpos,cascadeWeights)
	#endif

	fixed4 getCascadeWeights(float z)
	{
		return float4(z >= _LightSplitsNear) * float4(z < _LightSplitsFar);
	}

	fixed4 getCascadeWeights_splitSpheres(float3 wpos)
	{
		float3 fromCenter0 = wpos - unity_ShadowSplitSpheres[0];
		float3 fromCenter1 = wpos - unity_ShadowSplitSpheres[1];
		float3 fromCenter2 = wpos - unity_ShadowSplitSpheres[2];
		float3 fromCenter3 = wpos - unity_ShadowSplitSpheres[3];
		float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));
		fixed4 weights = float4(distances2 < unity_ShadowSplitSqRadii);
		weights.yzw = saturate(weights.yzw - weights);
		return weights;
	}

	float getShadowFade(float z)
	{
		return saturate(z * _LightShadowData.z + _LightShadowData.w);
	}

	float getShadowFade_SplitSpheres(float3 wpos)
	{	
		return saturate(distance(wpos.xyz, unity_ShadowFadeCenterAndType.xyz) * _LightShadowData.z + _LightShadowData.w);	
	}

	float4 getShadowCoord(float4 wpos, fixed4 cascadeWeights)
	{
		float3 sc0 = mul(unity_World2Shadow[0], wpos);
		float3 sc1 = mul(unity_World2Shadow[1], wpos);
		float3 sc2 = mul(unity_World2Shadow[2], wpos);
		float3 sc3 = mul(unity_World2Shadow[3], wpos);
		return float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 0.0f);
	}

	float4 getShadowCoord_SingleCascade(float4 wpos)
	{
		return float4(mul(unity_World2Shadow[0], wpos).xyz, 0.0f);
	}

	half unity_sampleShadowmap(float4 coord)
	{
		coord.xy = round(coord.xy * _ShadowMapTexture_TexelSize.zw) * _ShadowMapTexture_TexelSize.xy + _ShadowMapTexture_TexelSize.xy * 0.5f;
		half shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, coord);
		return shadow * (1.0 - _LightShadowData.r) + _LightShadowData.r;
	} 

	struct v2f
	{
						float4 pos		: SV_POSITION;
		noperspective float2 uv			: TEXCOORD0;
		noperspective float3 ray		: TEXCOORD1;
		noperspective float4 orthoPos	: TEXCOORD2;
	};

	v2f vert (appdata_base v)
	{
		v2f OUT;
		OUT.uv = v.texcoord;
		OUT.ray = v.normal;
		float4 clipPos = mul(UNITY_MATRIX_MVP, v.vertex);
		OUT.pos = clipPos;

		clipPos.y *= _ProjectionParams.x;
		float3 orthoNearPos = mul(unity_CameraInvProjection, float4(clipPos.xy, -1.0f, 1.0f)).xyz;
		OUT.orthoPos = float4(orthoNearPos.xy, -orthoNearPos.z, -dot(unity_CameraInvProjection[2], float4(clipPos.xy, 1.0f, 1.0f)));
		return OUT;
	}

	fixed4 frag (v2f IN) : SV_Target
	{
		float zdepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, IN.uv);

		IN.orthoPos.z = lerp(IN.orthoPos.z, IN.orthoPos.w, zdepth);
		float4 vPos = float4(lerp(IN.ray * lerp(Linear01Depth(zdepth), zdepth, unity_OrthoParams.w), IN.orthoPos, unity_OrthoParams.w), 1.0f);

		float4 wPos = mul(_CameraToWorld, vPos);

		half shadow = unity_sampleShadowmap(GET_SHADOW_COORDINATES(wPos, GET_CASCADE_WEIGHTS(wPos, vPos.z)));
		shadow += GET_SHADOW_FADE(wPos, vPos.z);

		return shadow;
	}

	ENDCG
}
}
}