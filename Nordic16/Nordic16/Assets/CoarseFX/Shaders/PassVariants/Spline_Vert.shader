Shader "CoarseFX/Spline/Vertex" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	[PowerSlider(2)] _Tesselation ("Tesselation", Range(1,16)) = 1 
	_FogIntns("Fog Intensity", Range(0,1)) = 1
	[Blending] _Blend ("Blending", Vector) = (1,1,1,1) 
	[LightModeDrawer] _Lighting ("Lighting" , Vector) = (1,1,0,0)
	[HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Depth Test", Float) = 4
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1 
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operator", Float) = 0
	[HideInInspector] [Toggle] _ZWrite ("Depth Write", Float) = 0
}
SubShader {
	Tags { "Queue"="Geometry" "RenderType"="Opaque" }
UsePass "Hidden/CoarseFX/Spline/VERTEX"
UsePass "Hidden/CoarseFX/Spline/SHADOWCASTER"
}//SubShader
}//Shader