Shader "CoarseFX/Particle Line/Forward" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
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
	Tags { "Queue"="Transparent" "RenderType"="Transparent" "PreviewType"="Plane" }
UsePass "Hidden/CoarseFX/Particle Line/FORWARDBASE"
UsePass "Hidden/CoarseFX/Particle Line/FORWARDADD"
UsePass "Hidden/CoarseFX/Particle Line/VERTEX"
UsePass "Hidden/CoarseFX/Particle Line/SHADOWCASTER"
}//SubShader
}//Shader