Shader "ballroom/FakeUpperLight" {
    Properties {
        _FadeTexture("渐隐贴图", 2D) = "white" {}
        _MainCol ("颜色", color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPow ("高光次幂", range(1, 90)) = 30
        _LightDirection("光方向", vector) = (0,0,0,0)
        _BottomColor("底部颜色", color) = (0.0, 0.0, 0.0, 1.0)
        _BottomHight("底部高度", float) = 0
        _BottomFade("底部渐隐度", float) = 2
        [Header(Diffuse)]
        _EnvUpCol   ("环境天顶颜色", Color)             = (1.0, 1.0, 1.0, 1.0)
        _EnvSideCol ("环境水平颜色", Color)             = (0.5, 0.5, 0.5, 1.0)
        _EnvDownCol ("环境地表颜色", Color)             = (0.0, 0.0, 0.0, 0.0)
//        _EnvDiffInt ("环境光强度",  Range(0, 1))    = 0.2



    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            // #include "cginc/MyCginc.cginc"
            #include "AutoLight.cginc"
            // #include "Lighting.cginc"

            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0
            // 输入参数
            // 修饰字（满足小朋友太多的问好, 想保发量的大家看热闹）
                // uniform  共享于vert,frag
                // attibute 仅用于vert
                // varying  用于vert,frag传数据
            sampler2D _FadeTexture;
            uniform float3 _MainCol;     // RGB够了 float3
            uniform float _SpecularPow;  // 标量 float
            uniform float _BottomHight;
            uniform float _BottomFade;
            uniform float3 _BottomColor;
            uniform float4 _LightDirection;
            uniform float3 _EnvDownCol;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            // uniform float _EnvDiffInt;



            // 输入结构
            struct VertexInput {
                float4 vertex : POSITION;   // 顶点信息 Get✔
                float4 normal : NORMAL;     // 法线信息 Get✔
                float2 uv : TEXCOORD0;
            };
            // 输出结构
            struct VertexOutput {
                float4 posCS : SV_POSITION;     // 裁剪空间（暂理解为屏幕空间吧）顶点位置
                float4 posWS : TEXCOORD0;       // 世界空间顶点位置
                float3 nDirWS : TEXCOORD1;      // 世界空间法线方向
                float2 uv : TEXCOORD2;
                LIGHTING_COORDS(5,6)
            };
            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;                   // 新建输出结构
                    o.posCS = UnityObjectToClipPos( v.vertex );     // 变换顶点位置 OS>CS
                    o.posWS = mul(unity_ObjectToWorld, v.vertex);   // 变换顶点位置 OS>WS
                    o.nDirWS = UnityObjectToWorldNormal(v.normal);  // 变换法线方向 OS>WS
                    o.uv = v.uv;
                TRANSFER_VERTEX_TO_FRAGMENT(o)      
                return o;                                           // 返回输出结构
            };
            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR {
                // 准备向量
                float3 nDir = normalize(i.nDirWS);

                // float3 nDirWS = i.nDirWS;

                // float3 lDir = _WorldSpaceLightPos0.xyz;
                float3 lDir = _LightDirection;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 hDir = normalize(vDir + lDir);
                // 准备点积结果
                // float ndotl = dot(nDir, lDir);
                float ndoth = dot(nDir, hDir);
                // 光照模型
                // float3 envCol = TriColAmbient(nDir, _EnvUpCol, _EnvSideCol, _EnvDownCol);
                float uMask = max(0.0, nDir.g);        // 获取朝上部分遮罩
                float dMask = max(0.0, -nDir.g);       // 获取朝下部分遮罩
                float sMask = 1.0 - uMask - dMask;  // 获取侧面部分遮罩
                float3 envCol = _EnvUpCol * uMask +
                                _EnvSideCol * sMask +
                                _EnvDownCol * dMask;       // 混合环境色

                // float lambert = max(0.0, ndotl);
                float blinnPhong = pow(max(0.0, ndoth), _SpecularPow);
                float3 finalRGB = _MainCol * blinnPhong  + envCol;
                float bottomValue = clamp((i.posWS.y - _BottomHight) / _BottomFade,0.0,1.0);
                
                finalRGB = finalRGB * bottomValue + _BottomColor * (1-bottomValue);
                float3 fadeValue = tex2D(_FadeTexture, i.uv);
                finalRGB = finalRGB * fadeValue;
                // 返回结果
                return float4(finalRGB, 1.0);
                // return float4(envCol, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}