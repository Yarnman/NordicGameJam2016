Shader "CoarseFX/Sky Dynamic" {
Properties {
	_SkyColor ("Sky Color", Color) = (1,1,1,1)
	_EquatorColor ("Equator Color", Color) = (1,1,1,1)
	_GroundColor ("Ground Color", Color) = (1,1,1,1)

	_CloudCube ("Clouds Cubemap", Cube) = "black" {}
	_CloudColor ("Cloud Color", Color) = (1,1,1,1)

	_SunTex ("Sun Texture", 2D) = "black" {}
	_MoonTex ("Moon Texture", 2D) = "black" {}

	_RandomLut("Random Bayercentric LUT", 2D) = "black"
}
SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
	ZWrite Off
	CGINCLUDE
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	fixed4 _SkyColor;
	fixed4 _EquatorColor;
	fixed4 _GroundColor;

	samplerCUBE _CloudCube;
	fixed4 _CloudColor;

	sampler2D _SunTex;
	float4 _SunTex_ST;
	sampler2D _MoonTex;
	float4 _MoonTex_ST;

	Texture2D _RandomLut;

	ENDCG
Pass {
	Blend One Zero, Zero Zero
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag 

	struct v2f
	{
		float4 pos					: SV_POSITION;
		noperspective fixed3 atmos	: TEXCOORD0;
	};

	v2f vert (float4 pos : POSITION)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.pos = VertexQuantize(OUT.pos);

		OUT.atmos = lerp(pos.y > 0.0 ? _SkyColor.rgb : _GroundColor.rgb, _EquatorColor.rgb, pow(1.0 - abs(pos.y), 8.0));

		return OUT;
	}

	fixed4 frag(v2f IN) : SV_TARGET
	{
		return fixed4(IN.atmos, 1.0);
	}
	ENDCG 
}
Pass {
	Blend One One
	CGPROGRAM 
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag

		struct v2g
	{
		float4 pos 	: SV_POSITION;
		float2 vPos	: TEXCOORD0;
		float3 oPos	: TEXCOORD1;
	};

	struct g2f
	{
		float4 pos	: SV_POSITION;
		float alpha : TEXCOORD0;
	};

	v2g vert(float3 pos : POSITION)
	{
		v2g OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.oPos = pos;

		OUT.vPos = mul(UNITY_MATRIX_MVP, pos).xy / dot(UNITY_MATRIX_MVP[3], pos);

		return OUT;
	}

	[maxvertexcount(16)]
	void geom(triangle v2g IN[3], inout PointStream<g2f> stream, uint id : SV_PrimitiveID)
	{
		float a = distance(IN[0].oPos, IN[1].oPos);
		float b = distance(IN[1].oPos, IN[2].oPos);
		float c = distance(IN[2].oPos, IN[0].oPos);
		float s = (a + b + c) * 0.5f;
		uint count = min(16, sqrt(s * (s - a) * (s - b) * (s - c)) * 512);

		uint id204 = id * 26;

		g2f OUT;
		for (uint i = 0; i < count; i++)
		{
			float4 rnd = _RandomLut.Load(uint3((i + id204) % 512, 0, 0));
			OUT.pos = float4(IN[0].vPos * rnd.x + IN[1].vPos * rnd.y + IN[2].vPos * rnd.z, 1.0f, 1.0f);
			OUT.alpha = rnd.w * (length(OUT.pos.xy) * 0.75 + 0.25);
			stream.Append(OUT);
		}
	}

	fixed4 frag(g2f IN) : SV_TARGET
	{
		return IN.alpha;
	}
	ENDCG
}
Pass {
	Blend SrcAlpha OneMinusSrcAlpha
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag 

	struct v2f
	{
		float4 pos						: SV_POSITION;
		noperspective float4 clouds		: TEXCOORD0;
		nointerpolation float2 remap	: TEXCOORD1;
	};

	v2f vert (float4 pos : POSITION)
	{
		v2f OUT;
		OUT.clouds.xyz = pos.xyz;
		float2 sc; sincos(_Time.x * 0.5, sc.x, sc.y);
		OUT.clouds.xz = mul(float2x2(sc.y, -sc.x, sc), OUT.clouds.xz);
		float3 lPos = _WorldSpaceLightPos0.xyz;
		lPos.y *= abs(lPos.y);

		float lDotN = dot(normalize(lPos), pos.xyz);
		OUT.clouds.w = saturate(-lDotN);
		OUT.clouds.w *= OUT.clouds.w * 0.25;
		OUT.clouds.w += pow(saturate(lDotN), 32.0) * 0.25;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos); 
		OUT.pos = VertexQuantize(OUT.pos);
		OUT.remap.x = 1.0f / _CloudColor.a;
		OUT.remap.y = _CloudColor.a * OUT.remap.x - OUT.remap.x;

		return OUT;
	}

	fixed4 frag(v2f IN) : SV_TARGET
	{
		fixed clouds = texCUBE(_CloudCube, IN.clouds).a * IN.remap.x + IN.remap.y;
		fixed4 outcol = fixed4(IN.clouds.w * _LightColor0.rgb + _CloudColor.rgb, clouds);
		//if (_ScreenParams.x == _ScreenParams.y)
		//	return outcol;
		//else
			return OutputDither(outcol, IN.pos.xy); 
	}
	ENDCG 
}
}
}