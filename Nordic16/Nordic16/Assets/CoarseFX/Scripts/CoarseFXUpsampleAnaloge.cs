using UnityEngine;

[ExecuteInEditMode]
public class CoarseFXUpsampleAnaloge : MonoBehaviour
{
    [SerializeField, HideInInspector]
    private Shader shaderUpsample;

    [Header("NTSC")]
    [Range(0f, 16f)]
    public float lumaBleed = 1f;

    [Range(0f, 16f)]
    public float chromaBleed = 1f;

    [Range(0f, 1f)]
    public float noise = 1f;

    [Header("CRT")]
    [Range(0f, 1f)]
    public float verticalBlur = 0.5f;
    
    [Range(0f, 1f)]
    public float horizontalBlur = 0.5f;
    
    [Range(0f, 1f)]
    public float masking = 0.5f;

    CoarseFXQuality.Resolution res;
    Material matUpsample;
    int scaleId, crtId, ntscId;

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        float screenAspect = (float)Screen.width / Screen.height;

        if (!res.lockImageAspect)
            matUpsample.SetVector(scaleId, new Vector4(1f, 1f, 0f, 0f));
        else if (screenAspect > res.imageAspect)
        {
            float scale = screenAspect / res.imageAspect;
            matUpsample.SetVector(scaleId, new Vector4(scale, 1f, scale * -0.5f + 0.5f, 0f));
        }
        else
        {
            float scale = res.imageAspect / screenAspect;
            matUpsample.SetVector(scaleId, new Vector4(1f, scale, 0f, scale * -0.5f + 0.5f));
        }

        matUpsample.SetVector(crtId, new Vector4(16f - verticalBlur * 15f, 8f - horizontalBlur * 7f, 1f - masking, 1f));
        matUpsample.SetVector(ntscId, new Vector4(lumaBleed, chromaBleed, noise, Time.realtimeSinceStartup % 1f));
        src.filterMode = FilterMode.Point;


        matUpsample.SetFloat("_FrameOddEven", Time.frameCount % 2 > 0 ? 1f : 0f);
        RenderTexture temp0 = RenderTexture.GetTemporary(src.width, src.height);
        RenderTexture temp1 = RenderTexture.GetTemporary(src.width, src.height);
        RenderTexture temp2 = RenderTexture.GetTemporary(Screen.width, src.height);
        src.filterMode = FilterMode.Point;
        temp2.filterMode = FilterMode.Point;
        Graphics.Blit(src, temp0, matUpsample, 0);
        Graphics.Blit(temp0, temp1, matUpsample, 1);
        Graphics.Blit(temp1, temp0, matUpsample, 2);
        Graphics.Blit(temp0, temp2, matUpsample, 3);
        Graphics.Blit(temp2, dst, matUpsample, 4);
        RenderTexture.ReleaseTemporary(temp0);
        RenderTexture.ReleaseTemporary(temp1);
        RenderTexture.ReleaseTemporary(temp2);
    }

    void OnEnable()
    {
        res = CoarseFXQuality.resolution;        
        matUpsample = new Material(shaderUpsample);
        matUpsample.hideFlags = HideFlags.HideAndDontSave;
        scaleId = Shader.PropertyToID("_Scale");
        crtId = Shader.PropertyToID("_CRTParams");
        ntscId = Shader.PropertyToID("_NTSCParams");
    }

    void OnDisable()
    {
        if (matUpsample)
            DestroyImmediate(matUpsample);
    }
}
