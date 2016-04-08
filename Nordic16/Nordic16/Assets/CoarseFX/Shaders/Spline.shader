Shader "Hidden/CoarseFX/Spline" {
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

	float _Tesselation;
	fixed _FogIntns;

	#define Interp(structId) OUT.structId = lerp(IN[0].structId, IN[1].structId, a);

	float3 Bezier(float a, float3 aPos, float3 bPos, float3 aBez, float3 bBez)
	{
		float b = 1.0f - a;
		float a2 = a * a;
		float b2 = b * b;
		float3 pos = aPos * b2 * b + bPos * a2 * a;
		pos += (aBez * b2 * a + bBez * a2 * b) * 3.0f;
		return pos;
	}

	float3 BezierTan(float a, float3 aPos, float3 bPos, float3 aBez, float3 bBez)
	{
		float b = 1.0f - a;
		float a2 = a * a;
		float b2 = b * b;
		float3 pos = (aBez - aPos) * b2 + (bPos - bBez) * a2;
		pos += (bBez - aBez) * b * a * 2.0f;
		return normalize(pos);
	}

	float3 ProjOnPlane(float3 vec, float3 plane)
	{
		return normalize(vec - dot(vec, plane) * plane);
	}

	struct tData
	{
		float TessFactor[2]    : SV_TessFactor;
	};

	tData hullConst()
	{
		tData OUT;
		OUT.TessFactor[0] = _Tesselation;
		OUT.TessFactor[1] = _Tesselation;
		return OUT;
	}

	#define HULL [domain("isoline")] \
	[partitioning("integer")] \
	[outputtopology("line")] \
	[patchconstantfunc("hullConst")] \
	[outputcontrolpoints(2)] \
	vData hull(InputPatch<vData, 2> IN, int id : SV_OutputControlPointID) \
	{ \
		return IN[id]; \
	} \
	[domain("isoline")]

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

	#define UNITY_PASS_FORWARDBASE

	struct vData
	{
						float4 pos	: SV_POSITION;
						float3 bPos	: TEXCOORD0;
		noperspective	fixed3 dir	: COLOR;
		noperspective	fixed4 amb	: COLOR1;
		COARSEFX_LIGHTING_COORDS(1,2)
		COARSEFX_FOG_COORD(3)

	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.bPos = v.normal;

		float dbFade = DepthBoundFade(v.vertex);

		OUT.dir = v.color * _Color * _LightColor0 * dbFade;
		OUT.amb = v.color * _Color * dbFade;

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		COARSEFX_TRANSFER_LIGHTING(OUT, float3(0,0,0));

		return OUT;
	}

	HULL

	vData dom(tData hData, OutputPatch<vData, 2> IN, float a : SV_DomainLocation)
	{
		vData OUT;

		float3 wPos = Bezier(a, IN[0].pos, IN[1].pos, IN[0].bPos, IN[1].bPos);
		float3 wTan = BezierTan(a, IN[0].pos, IN[1].pos, IN[0].bPos, IN[1].bPos);
		float3 wNorm = ProjOnPlane(normalize(_WorldSpaceCameraPos - wPos), wTan);
		OUT.pos = mul(UNITY_MATRIX_MVP, float4(wPos, 1.0f));
		OUT.bPos = OUT.pos;
		OUT.pos = VertexQuantize(OUT.pos);

		Interp(amb)
		OUT.amb.rgb *= AmbientLight(wNorm);

		Interp(dir)
		OUT.dir *= saturate(dot(_WorldSpaceLightPos0.xyz, wNorm));
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos);

		return OUT;
	}

	fixed4 frag(vData IN) : SV_Target
	{
		float dither = Dither(IN.pos);
		clip(IN.amb.a - dither);
		fixed3 atten = COARSEFX_LIGHT_ATTENUATION(IN);
		fixed4 outcol = fixed4(IN.amb.rgb + IN.dir * atten, 1.0);
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

	#define UNITY_PASS_FORWARDADD

	struct vData
	{
						float4 pos	: SV_POSITION;
		noperspective	fixed4 dir	: COLOR;
						float3 bPos	: TEXCOORD0;
		COARSEFX_LIGHTING_COORDS(1,2)
		COARSEFX_FOG_COORD(3)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.bPos = v.normal;

		float dbFade = DepthBoundFade(v.vertex);
		OUT.dir = v.color * _Color * dbFade;
		OUT.dir.rgb *= _LightColor0.rgb;

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		COARSEFX_TRANSFER_LIGHTING(OUT, float3(0,0,0));

		return OUT;
	}

	HULL

	vData dom(tData hData, OutputPatch<vData, 2> IN, float a : SV_DomainLocation)
	{
		vData OUT;

		float3 wPos = Bezier(a, IN[0].pos.xyz, IN[1].pos.xyz, IN[0].bPos, IN[1].bPos);
		float3 wTan = BezierTan(a, IN[0].pos.xyz, IN[1].pos.xyz, IN[0].bPos, IN[1].bPos);
		float3 wNorm = ProjOnPlane(normalize(_WorldSpaceCameraPos - wPos), wTan);
		OUT.pos = mul(UNITY_MATRIX_MVP, float4(wPos, 1.0f));
		OUT.bPos = OUT.pos;
		OUT.pos = VertexQuantize(OUT.pos);
		
		float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - wPos * _WorldSpaceLightPos0.w);

		Interp(dir)
		OUT.dir.rgb *= saturate(dot(lightDir, wNorm));
		#if SPOT || POINT || POINT_COOKIE
			OUT.dir.rgb *= 1.0f - length(mul(_LightMatrix0, float4(wPos, 1.0f)).xyz);
		#endif

		COARSEFX_TRANSFER_LIGHTING(OUT, wPos);
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}
	
	fixed4 frag(vData IN) : SV_Target
	{
		float dither = Dither(IN.pos.xy);
		fixed3 light = IN.dir.rgb * COARSEFX_LIGHT_ATTENUATION(IN);

		clip(IN.dir.a - dither);
		fixed4 outcol = fixed4(light, 1.0);
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, fixed3(0.0, 0.0, 0.0));
		return Output(outcol, dither);
	}
	ENDCG
}//Pass ForwardAdd
Pass {
	Name "VERTEX"
	Tags { "LightMode"="Vertex" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom

	struct vData
	{
						float4 pos	: SV_POSITION;
						float3 bPos	: TEXCOORD0;
		noperspective	fixed4 dir	: COLOR;
		COARSEFX_FOG_COORD(1)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.bPos = v.normal;
		float dbFade = DepthBoundFade(v.vertex);
		OUT.dir = v.color * _Color * dbFade;

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		
		return OUT;
	}

	HULL

	vData dom(tData hData, OutputPatch<vData, 2> IN, float a : SV_DomainLocation)
	{
		vData OUT;

		float3 wPos = Bezier(a, IN[0].pos, IN[1].pos, IN[0].bPos, IN[1].bPos);
		float3 wTan = BezierTan(a, IN[0].pos, IN[1].pos, IN[0].bPos, IN[1].bPos);
		float3 wNorm = ProjOnPlane(normalize(_WorldSpaceCameraPos - wPos), wTan);
		OUT.pos = mul(UNITY_MATRIX_MVP, float4(wPos, 1.0f));
		OUT.bPos = OUT.pos;
		OUT.pos = VertexQuantize(OUT.pos);

		Interp(dir)
		OUT.dir.rgb *= VertexLightOpaque(mul(UNITY_MATRIX_MV, float4(wPos, 1.0f)), mul((float3x3)UNITY_MATRIX_IT_MV, wNorm), wNorm.y);

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}
	
	fixed4 frag(vData IN) : COLOR
	{
		float dither = Dither(IN.pos);
		clip(IN.dir.a - dither);
		fixed3 light = IN.dir;
		fixed4 outcol = fixed4(light, 1.0);
		COARSEFX_APPLY_FOG(IN, outcol);
		return Output(outcol, dither);
	}
	ENDCG
}//Pass Vertex
Pass {
	Name "SHADOWCASTER"
	Tags { "LightMode"="ShadowCaster" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_shadowcaster

	struct vData
	{
		V2F_SHADOW_CASTER;
						float3 bPos	: TEXCOORD2;
		noperspective	fixed2 alpha	: TEXCOORD3;
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		#ifdef SHADOWS_CUBE
			OUT.vec = OUT.pos;
		#elif UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
			OUT.hpos = OUT.pos;
		#endif
		OUT.bPos = v.normal;

		OUT.alpha = _Color.a * v.color.a;

		return OUT;
	}

	HULL

	vData dom(tData hData, OutputPatch<vData, 2> IN, float a : SV_DomainLocation)
	{
		vData OUT;

		float3 wPos = Bezier(a, IN[0].pos, IN[1].pos, IN[0].bPos, IN[1].bPos);
		OUT.pos = mul(UNITY_MATRIX_MVP, float4(wPos, 1.0f));
		OUT.pos = UnityApplyLinearShadowBias(OUT.pos);
		OUT.bPos = OUT.pos;
		if (abs(UNITY_MATRIX_P._m00) != abs(UNITY_MATRIX_P._m11))
			OUT.pos = VertexQuantize(OUT.pos);

		#ifdef SHADOWS_CUBE
			OUT.vec = wPos - _LightPositionRange.xyz;
		#elif UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
			OUT.pos = hpos;
		#endif

		Interp(alpha)
		return OUT;
	}

	float4 frag(vData IN) : COLOR
	{
		clip(IN.alpha.x - Dither(IN.pos));
		SHADOW_CASTER_FRAGMENT(IN)
	}
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader