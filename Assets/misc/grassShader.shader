﻿Shader "Unlit/grassShader"
{
	Properties
	{
		colorTex("Diffuse Map", 2D) = "white" {}
		normalTex("Normal Map", 2D) = "white" {}
		shadowTex("Shadow Map", 2D) = "white" {}

		lightPosition("light position (normalized)", Vector) = (0, 1, 0, 0)
		lightColor("light Color", Color) = (1,1,1,1)
		ambientColor("ambient Color", Color) = (0.5,0.5,0.5,1)

		doubleSideRatio("double side ratio", float) = 3

		cameraPosition("local position of the shadow map camera (toOrigin)", Vector) = (0, 17.57, 0, 0)
		cameraY("-Y Axis of the camera", Vector) = (0, -1, 0, 0)
		cameraX("X Axis of the camera", Vector) = (1, 0, 0, 0)
		cameraZ("Z Axis of the camera", Vector) = (0, 0, 1, 0)
		cameraRadius("Size of the ortho shadow map camera", float) = 9
		cameraNear("Near plane", float) = 1
		cameraFar("Far plane", float) = 24
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normal : POSITION1;
				float4 vertex : POSITION;
				float3 position : COLOR0;
			};

			uniform sampler2D colorTex, normalTex, shadowTex;

			uniform float3 lightPosition;
			uniform float4 ambientColor, lightColor;
			uniform float doubleSideRatio;

			uniform float3 cameraPosition, cameraY, cameraX, cameraZ;
			uniform float cameraRadius, cameraNear, cameraFar;

			v2f vert(appdata v)
			{
				v2f o;

				//Waving
				if (v.uv.y > 0.5)
				{
					v.vertex.x += _SinTime.w * 0.6;
					v.vertex.z += _CosTime.z * 0.4;
				}

				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				//o.normal = mul(_Object2World, v.normal).xyz;
				o.normal = v.normal.xyz;
				o.position = mul(_Object2World, v.vertex).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//get texture
				fixed4 col = tex2D(colorTex, i.uv);

				//alpha culling
				if (col.a < 0.5)
				{
					clip(-1.0);
				}

				//Calc shadows
				float x = (i.position.x * cameraX.x + i.position.y * cameraX.y + i.position.z * cameraX.z) / (cameraRadius * 2) + 0.5;
				float z = (i.position.x * cameraZ.x + i.position.y * cameraZ.y + i.position.z * cameraZ.z) / (cameraRadius * 2) + 0.5;

				float4 depthTex = tex2D(shadowTex, float2(x, z));
				if (!(depthTex.r >= 0.99))
				{
					//Calc dis to camera
					float3 v3ToCam = cameraPosition.xyz - i.position.xyz;
					float dist = -dot(v3ToCam, cameraY);
					float depth = (dist - cameraNear) / (cameraFar - cameraNear);

					if (depth - depthTex.r > 0.05)
					{
						col *= 0.75;
					}
				}

				float3 lookDir = i.position - _WorldSpaceCameraPos;
				lookDir = normalize(lookDir);
				//float3 lookDir = normalize(i.normal);
				fixed4 colYellow = fixed4(col.g * 0.9, col.g, col.g * 0.2, 1.0) * lightColor * 1.5;
				col *= ambientColor;
				float factor = pow(abs(dot(lookDir, lightPosition)), doubleSideRatio);

				//Double-Sided
				col = (1 - factor) * col + factor * colYellow;
				//col.rgb = i.normal;

				return col;
			}
			ENDCG
		}
	}
}
