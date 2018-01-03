#include "HostDeviceData.h"

struct Camera
{
    CameraData data;
};

interface ILayerProperties
{
    LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point);
    LightingResult blend(LightingResult current, LightingResult previous);    
}

interface IMaterialLayer
{
    associatedtype LayerProperties : ILayerProperties;
    // light independent computations
    LayerProperties evalLayerProperties(PreshadedSurfacePoint point);    
};

struct CompositeLayer<TLayer : IMaterialLayer, TTail: IMaterialLayer> : IMaterialLayer
{
    struct LayerProperties : ILayerProperties
    {
        TLayer.LayerProperties headProps;
        TTail.LayerProperties tailProps;
        LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
        {
            LightingResult headRs = headProps.evalLighting(ls, point);
            return headProps.blend(headRs, tailProps.evalLighting(ls, point));
        }
        LightingResult blend(LightingResult previous)
        {
            LightingResult rs;
            // should not be called
            return rs;
        }
    };
    TLayer head;
    TTail tail;
    LayerProperties evalLayerProperties(PreshadedSurfacePoint point)
    {
        LayerProperties props;
        props.headProps = head.evalLayerProperties(point);
        props.tailProps = tail.evalLayerProperties(point);
        return props;
    }
};

struct LambertLayer : IMaterialLayer
{
    struct LayerProperties : ILayerProperties
    {
        float4 albedo;
        float pmf;
        LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
        {
            LightingResult rs = InitLightingResult();
            float3 value = ls.intensity;
            float weight = 0;
            #ifndef _MS_DISABLE_DIFFUSE
                value *= evalDiffuseBSDF(normal, lightDir);
                weight = albedo.w;
                rs.diffuseAlbedo = albedo.rgb * layer.pmf;
                rs.diffuse = value;
            #endif
            return rs;            
        }
        LightingResult blend(LightingResult previous)
        {
            
        }
    };
    LayerProperties evalLayerProperties(PreshadedSurfacePoint point)
    {

    }
};

struct EmissiveLayer : IMaterialLayer
{
    struct LayerProperties : ILayerProperties
    {
        LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
        {
            
        }
        LightingResult blend(LightingResult previous)
        {
            
        }
    };
    LayerProperties evalLayerProperties(PreshadedSurfacePoint point)
    {
        
    }
};

struct SpecularLayer : IMaterialLayer
{
    struct LayerProperties : ILayerProperties
    {
        LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
        {
            
        }
        LightingResult blend(LightingResult previous)
        {
            
        }
    };
    LayerProperties evalLayerProperties(PreshadedSurfacePoint point)
    {
        
    }
};

struct DynamicMaterialLayer : IMaterialLayer
{
    struct LayerProperties : ILayerProperties
    {
        float4     albedo;                                       ///< Material albedo/specular color/emitted color
        float4     roughness;                                    ///< Material roughness parameter [0;1] for NDF
        float4     extraParam;                                   ///< Additional user parameter, can be IoR for conductor and dielectric
        float3     pad             DEFAULTS(float3(0, 0, 0));
        float      pmf             DEFAULTS(0.f);                 ///< Specifies the current value of the PMF of all layers. E.g., first layer just contains a probability of being selected, others accumulate further

        LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
        {

        }
        LightingResult blend(LightingResult previous)
        {

        }
    };

    uint32_t    type            DEFAULTS(MatNone);             ///< Specifies a material Type: diffuse/conductor/dielectric/etc. None means there is no material
    uint32_t    ndf             DEFAULTS(NDFGGX);              ///< Specifies a model for normal distribution function (NDF): Beckmann, GGX, etc.
    uint32_t    blending        DEFAULTS(BlendAdd);            ///< Specifies how this layer should be combined with previous layers. E.g., blended based on Fresnel (useful for dielectric coatings), or just added on top, etc.

    LayerProperties evalLayerProperties(PreshadedSurfacePoint point)
    {
        DynamicLayerProperties rs;
        // ...
        return rs;
    }
};

struct LightingResult
{
    float4 ambient, emissive, diffuse, specular;
};

struct LightSample
{
    float3 lightPos;
    float3 lightDir;
    float3 intensity;
};

interface ILight
{
    int getLightSampleGroupCount(PreshadedSurfacePoint point);
    int getLightSampleCount(PreshadedSurfacePoint point, int groupId);
    LightSample getLightSample(PreshadedSurfacePoint point, int groupId, int i);
}

struct DynamicLight : ILight
{
    LightData lightData;
    int getLightSampleGroupCount(PreshadedSurfacePoint point)
    {
        return 1;
    }
    int getLightSampleCount(PreshadedSurfacePoint point, int groupId)
    {
        return 1;
    }
    LightSample getLightSample(PreshadedSurfacePoint point, int groupId, int i)
    {
        LightSample rs;
        // compute light intensity at specified shading point

        return rs;
    }
};

struct DynamicLightEnvironment : ILight
{
    DyanmicLight lights[MaxLights];
    int numLights;
    int getLightSampleGroupCount(PreshadedSurfacePoint point)
    {
        return numLights;
    }
    int getLightSampleCount(PreshadedSurfacePoint point, int groupId)
    {
        return lights[groupId].getLightSampleCount(point, 0);
    }
    LightSample getLightSample(PreshadedSurfacePoint point, int groupId, int i)
    {
        return lights[groupId].getLightSample(point, 0, i);
    }
};

interface ISurfaceProperties
{
    LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point);
};

interface IMaterial
{
    associatedtype SurfaceProperties : ISurfaceProperties;
    SurfaceProperties evalSurfaceProperties(PreshadedSurfacePoint surfPoint);        
    PreshadedSurfacePoint preShade(SurfacePoint point);
}

struct SurfacePoint
{
    float3    P;                                  ///< Shading hit position in world space
    float3    E;                                  ///< Direction to the eye at shading hit
    float3    N;                                  ///< Shading normal at shading hit
    float3    T;                                  ///< Shading tangent at shading hit
    float3    B;                                  ///< Shading bitangent at shading hit
    float2    UV;                                 ///< Texture mapping coordinates
};

struct PreshadedSurfacePoint
{
    SurfacePoint point;
    float lodBias;
    float aoFactor;
};

struct DynamicSurfaceProperties : ISurfaceProperties
{
    DynamicLayerProperties layers[MatMaxLayers];
    int numLayers;
    LightingResult evalLighting(LightSample ls, PreshadedSurfacePoint point)
    {
        LightingResult rs = InitLightingResult();
        for (int i = 0; i < numLayers; i++)
        {
            LightingResult layerRs = layers[i].evalLighting(ls, point);
            rs = layers[i].blend(rs, layerRs);
        }
        return rs;
    }
};

// could turn this into a generic, but don't want to go that far yet
struct OptionalInputTexture
{
    Texture2D texture;
    bool hasTexture;
};

interface IInputChannel
{
    float4 getValue(SamplerState sampler, float2 uv);
};

struct ConstantInputChannel
{
    float4 constant;
    float4 getValue(SamplerState sampler, float2 uv)
    {
        return constant;
    }
};

struct TextureInputChannel
{
    Texture2D texture;
    float4 getValue(SamplerState sampler, float2 uv)
    {
        return texture.Sample(sampler, uv);        
    }
};

struct MaterialPreShader
{
    OptionalInputTexture alphaMap;         // Alpha test parameter, if texture is non-null, alpha test is enabled, alpha threshold is stored in the constant color
    OptionalInputTexture normalMap;        // Normal map modifier, if texture is non-null, shading normal is perturbed
    OptionalInputTexture heightMap;        // Height (displacement) map modifier, if texture is non-null, one can apply a displacement or parallax mapping
    OptionalInputTexture ambientMap;       // Ambient occlusion map
    PreshadedSurfacePoint preShade(SurfacePoint point)
    {
        PreshadedSurfacePoint rs;
        // apply alpha test, ao, normal map, height map here

        return rs;
    }
};

struct DynamicMaterial : IMaterial
{
    DynamicMaterialLayer layers[MatMaxLayers];
    int numLayers;
    MaterialPreShader preShader;
    PreshadedSurfacePoint preShade(SurfacePoint point)
    {
        return preShader.preShade(point);
    }

    DynamicSurfaceProperties evalSurfaceProperties(PreshadedSurfacePoint point)
    {
        DynamicSurfaceProperties rs;
        rs.numLayers = numLayers;
        for (int i = 0; i < numLayers; i++)
        {
            rs.layers[i] = layers[i].evalLayerProperties(point);
        }
        return rs;
    }
};

struct SpecializedMaterial<TLayer : IMaterialLayer> : IMaterial
{
    TLayer layer;

    MaterialPreShader preShader;
    PreshadedSurfacePoint preShade(SurfacePoint point)
    {
        return preShader.preShade(point);
    }
    struct SurfaceProperties
    {
        TLayer.LayerProperties layerProps;
    };

    SurfaceProperties evalSurfaceProperties(PreshadedSurfacePoint point)
    {
        SurfaceProperties rs;
        rs.layerProps = layer.evalLayerProperties(point);
        return rs;
    }
};
