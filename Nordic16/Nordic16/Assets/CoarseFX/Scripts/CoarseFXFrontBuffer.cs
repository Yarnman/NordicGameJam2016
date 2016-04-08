using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Events;
#pragma warning disable 649

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CoarseFXFrontBuffer : MonoBehaviour
{
    class PostEffect
    {
        Behaviour behaviour;
        MethodInfo method;

        public static PostEffect GetValid(Behaviour behaviour)
        {
            if (!behaviour.enabled)
                return null;
            MethodInfo method = UnityEventBase.GetValidMethodInfo(behaviour, "OnRenderImage", new Type[] { typeof(RenderTexture), typeof(RenderTexture) });
            return method != null ? new PostEffect(behaviour, method) : null;
        }

        PostEffect(Behaviour behaviour, MethodInfo method)
        {
            this.behaviour = behaviour;
            this.method = method;
        }

        public void Render(RenderTexture src, RenderTexture dst)
        {
            method.Invoke(behaviour, new RenderTexture[] { src, dst });
        }
    }
    class CameraInfo
    {
        public Camera cam;
        public Rect rectOrg, rectSat;
        public bool sliced;

        public CameraInfo(Camera cam, Rect org, Rect sat, bool sliced)
        {
            this.cam = cam;
            rectOrg = org;
            rectSat = sat;
            this.sliced = sliced;
        }
    }
    Coroutine routine;
    List<PostEffect> postEffectsLow = new List<PostEffect>();
    List<PostEffect> postEffectsHigh = new List<PostEffect>();
    List<CameraInfo> camInfos = new List<CameraInfo>();
    Dictionary<Camera, CameraInfo> camList = new Dictionary<Camera, CameraInfo>();

    public Behaviour customUpsampler;
    PostEffect upsampler;

    [SerializeField, HideInInspector]
    private Shader shaderClear, shaderComposite, shaderUpsample, shaderCubemap;
    static CoarseFXQuality.Resolution res;
    static RenderTexture tex;
    static Material matClear, matComposite, matUpsample, matCubemap;
    static int scaleId, frameId;
    static int oldWidth, oldHeight;
    static Rect rectIdentity = new Rect(0f, 0f, 1f, 1f);
    
    void FinalBlit()
    {
        if (!tex)
            return;
        if (res.progressive || res.cubemap)
        {
            int start = camInfos.Count - 1;
            while (start >= 0)
            {
                if (!camInfos[start].sliced)
                    break;
                start--;
            }
            
            for (int i = start + 1, n = camInfos.Count; i < n; i++)
            {
                Composite(camInfos[i]);
                RenderTexture.ReleaseTemporary(camInfos[i].cam.targetTexture);
                camInfos[i].cam.targetTexture = null;
                camInfos[i].cam.rect = camInfos[i].rectOrg;
            }

            for (int i = start; i >= 0; i--)
            {
                if (camInfos[i].sliced)
                    RenderTexture.ReleaseTemporary(camInfos[i].cam.targetTexture);
                camInfos[i].cam.targetTexture = null;
                camInfos[i].cam.rect = camInfos[i].rectOrg;
            }
        }
        else
            for (int i = 0, n = camInfos.Count; i < n; i++)
            {
                Composite(camInfos[i]);
                RenderTexture.ReleaseTemporary(camInfos[i].cam.targetTexture);
                camInfos[i].cam.targetTexture = null;
                camInfos[i].cam.rect = camInfos[i].rectOrg;
            }
        camInfos.Clear();
        camList.Clear();

        upsampler = customUpsampler ? PostEffect.GetValid(customUpsampler) : null;
        postEffectsHigh.Clear();
        postEffectsLow.Clear();

        bool underThis = false;
        Behaviour[] behaviours = GetComponents<Behaviour>();
        for (int i = 0; i < behaviours.Length; i++)
        {
            if (behaviours[i] == customUpsampler)
                continue;
            underThis |= behaviours[i] == this as Behaviour;
            PostEffect post = PostEffect.GetValid(behaviours[i]);
            if (post != null)
            {
                if (underThis)
                    postEffectsHigh.Add(post);
                else
                    postEffectsLow.Add(post);
            }
        }
        RenderTexture highSrc;
        switch (postEffectsLow.Count)
        {
            case 0:
                highSrc = tex;
                break;
            case 1:
                RenderTexture temp = RenderTexture.GetTemporary(res.width, res.height);
                postEffectsLow[0].Render(tex, temp);
                RenderTexture.ReleaseTemporary(temp);
                highSrc = temp;
                break;
            default:
                RenderTexture temp0 = RenderTexture.GetTemporary(res.width, res.height);
                RenderTexture temp1 = RenderTexture.GetTemporary(res.width, res.height);
                postEffectsLow[0].Render(tex, temp0);
                for (int i = 1, n = postEffectsLow.Count; i < n; i++)
                    postEffectsLow[i].Render(i % 2 == 0 ? temp1 : temp0, i % 2 == 0 ? temp0 : temp1);
                RenderTexture.ReleaseTemporary(temp0);
                RenderTexture.ReleaseTemporary(temp1);
                highSrc = postEffectsLow.Count % 2 == 0 ? temp1 : temp0;
                break;
        }
        switch (postEffectsHigh.Count)
        {
            case 0:
                RenderImage(highSrc, null);
                break;
            case 1:
                RenderTexture temp = RenderTexture.GetTemporary(Screen.width, Screen.height);
                RenderImage(highSrc, temp);
                postEffectsHigh[0].Render(temp, null);
                RenderTexture.ReleaseTemporary(temp);
                break;
            default:
                RenderTexture temp0 = RenderTexture.GetTemporary(Screen.width, Screen.height);
                RenderTexture temp1 = RenderTexture.GetTemporary(Screen.width, Screen.height);
                RenderImage(highSrc, temp0);
                for (int i = 0, n = postEffectsHigh.Count; i < n; i++)
                    postEffectsHigh[i].Render(i % 2 == 0 ? temp0 : temp1, i == n - 1 ? null : i % 2 == 0 ? temp1 : temp0);
                RenderTexture.ReleaseTemporary(temp0);
                RenderTexture.ReleaseTemporary(temp1);
                break;
        }
        if (res.progressive)
            matClear.DisableKeyword("_INTERLACE_ON");
        else
        {
            matClear.SetFloat(frameId, Time.frameCount % 2 > 0 ? 0.5f : 0f);
            matClear.EnableKeyword("_INTERLACE_ON");
        }
        RenderTexture.active = null;
    }
    Vector3 pos;
    Quaternion rot;
    int face;
    public Camera mainCam;
    void LateUpdate()
    {
        if (res.cubemap)
        {
            mainCam.enabled = false;
            pos = mainCam.transform.position;
            rot = mainCam.transform.rotation;
            face = 0;
            GL.invertCulling = false; 
            mainCam.RenderToCubemap(tex, 63);
        }
    }
    /*
     * 
            switch (face)
            {
                case 0:
                    //Right
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 90f, 0f), Vector3.one).inverse;
                    break;
                case 1:
                    //Left
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 270f, 0f), Vector3.one).inverse;
                    break;
                case 2:
                    //Front
                    newMat = Matrix4x4.TRS(pos, rot, Vector3.one).inverse;
                    break;
                default:
                    //Back
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 180f, 0f), Vector3.one).inverse;
                    break;
            }
            */

    void PreCull(Camera cam)
    {

        if (cam == mainCam && res.cubemap)
        {
            Matrix4x4 newMat;
            switch (face)
            {
                case 0:
                    //Right
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 90f, 0f), Vector3.one).inverse;
                    break;
                case 1:
                    //Left
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 270f, 0f), Vector3.one).inverse;
                    break;
                case 2:
                    //Bottom
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(90f, 0f, 0f), Vector3.one).inverse;
                    break;
                case 4:
                    //Front
                    newMat = Matrix4x4.TRS(pos, rot, Vector3.one).inverse;
                    break;
                case 5:
                    //Back
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(0f, 180f, 0f), Vector3.one).inverse;
                    break;
                default:
                    //Top
                    newMat = Matrix4x4.TRS(pos, rot * Quaternion.Euler(-90f, 0f, 0f), Vector3.one).inverse;
                    break;

            }
            newMat.m20 = -newMat.m20;
            newMat.m21 = -newMat.m21;
            newMat.m22 = -newMat.m22;
            newMat.m23 = -newMat.m23;
            cam.worldToCameraMatrix = newMat;
            face++;
            GL.invertCulling = false;
        }

        if (cam.targetTexture || cam.cameraType == CameraType.SceneView || cam.cameraType == CameraType.Preview || cam.name == "Preview Camera")
            return;
        if (camList.Count == 0 && (Screen.height != oldHeight || Screen.width != oldWidth))
        {
            res.ScreenUpdate();
            if (tex.width != res.width || tex.height != res.height)
                Reinitialize();
            oldWidth = Screen.width;
            oldHeight = Screen.height;
        }

        Rect rectOrg = cam.rect;
        Rect rectSat = Rect.MinMaxRect(Mathf.Clamp01(rectOrg.xMin), Mathf.Clamp01(rectOrg.yMin), Mathf.Clamp01(rectOrg.xMax), Mathf.Clamp01(rectOrg.yMax));
        Rect rectPixel = new Rect(Mathf.Floor(rectSat.x * res.width), Mathf.Floor(rectSat.y * res.height), Mathf.Ceil(rectSat.width * res.width), Mathf.Ceil(rectSat.height * res.height / 2f) * 2f);
        rectSat = new Rect(rectPixel.x / res.width, rectPixel.y / res.height, rectPixel.width / res.width, rectPixel.height / res.height);
            
        bool sliced = rectSat != rectIdentity && !res.cubemap;
        if (sliced)
        {
            cam.rect = rectIdentity;
            cam.targetTexture = RenderTexture.GetTemporary((int)rectPixel.width, (int)(rectPixel.height * (res.progressive ? 1f : 0.5f)), 16);
            cam.aspect = res.imageAspect * rectSat.width / rectSat.height;
        }
        else
        {
            if (res.progressive || res.cubemap)
                cam.targetTexture = tex;
            else
                cam.targetTexture = RenderTexture.GetTemporary(res.width, res.height / 2, 16);
            cam.aspect = res.cubemap ? 1f : res.imageAspect;
        }

        if (!res.progressive && !res.cubemap)
        {
            Matrix4x4 proj = cam.projectionMatrix;
            proj.m12 = ((Time.frameCount + (int)rectPixel.y) % 2 == 0 ? -1f : 1f) / (cam.pixelHeight * 2);
            cam.projectionMatrix = proj;
        }
        CameraInfo info = new CameraInfo(cam, rectOrg, rectSat, sliced);
        camInfos.Add(info);
        camList.Add(cam, info);
    }
    void PreRender(Camera cam)
    {
        GL.invertCulling = false;
    }

    void PostRender(Camera cam)
    {
        if (!camList.ContainsKey(cam))
            return;
        cam.ResetAspect();
        cam.ResetProjectionMatrix();
    }

    void Composite(CameraInfo info)
    {
        matComposite.SetVector(scaleId, new Vector4(info.rectSat.width, info.rectSat.height, info.rectSat.x * 2f - 1f + info.rectSat.width, 1f - info.rectSat.y * 2f - info.rectSat.height));

        if (res.progressive)
            matComposite.DisableKeyword("_INTERLACE_ON");
        else
        {
            matComposite.SetFloat(frameId, Time.frameCount % 2 > 0 ? 0.5f : 0f);
            matComposite.EnableKeyword("_INTERLACE_ON");
        }

        info.cam.targetTexture.filterMode = FilterMode.Point;
        GL.sRGBWrite = true;
        Graphics.Blit(info.cam.targetTexture, tex, matComposite);
    }

    void RenderImage(RenderTexture src, RenderTexture dst)
    {
        if (upsampler != null)
        {
            upsampler.Render(src, dst);
            return;
        }
        float screenAspect = (float)Screen.width / Screen.height;

        if (!res.lockImageAspect)
            matUpsample.SetVector(scaleId, new Vector4(res.width, res.height, 0f, 0f));
        else if (screenAspect > res.imageAspect)
        {
            float scale = screenAspect / res.imageAspect * res.width;
            matUpsample.SetVector(scaleId, new Vector4(scale, res.height, scale * -0.5f + 0.5f * res.width, 0f));
        }
        else
        {
            float scale = res.imageAspect / screenAspect * res.height;
            matUpsample.SetVector(scaleId, new Vector4(res.width, scale, 0f, scale * -0.5f + 0.5f * res.height));
        }

        if (!res.antialias || ((float)Screen.height / res.height % 1f == 0f && (float)Screen.width / res.width % 1f == 0f))
            matUpsample.DisableKeyword("_MAGNIFY_ON");
        else
            matUpsample.EnableKeyword("_MAGNIFY_ON");
        src.filterMode = FilterMode.Bilinear;
        GL.sRGBWrite = true;
        if (res.cubemap)
            Graphics.Blit(src, dst, matCubemap);
        else
            Graphics.Blit(src, dst, matUpsample);
    }

    void OnEnable()
    {
        Camera.onPreCull += PreCull;
        Camera.onPreRender += PreRender;
        Camera.onPostRender += PostRender;

        Camera cam = GetComponent<Camera>();
        cam.enabled = false;
        cam.hideFlags = HideFlags.HideInInspector;

        res = CoarseFXQuality.resolution;

        if (res.cubemap)
        {
            tex = new RenderTexture(res.cuberes, res.cuberes, 24);
            tex.isCubemap = true;
            tex.name = "CoarseFXCubemap";
        }
        else
        {
            tex = new RenderTexture(res.width, res.height, 16);
            tex.hideFlags = HideFlags.HideAndDontSave;
            tex.name = "CoarseFXBuffer";
        }
        tex.Create();

        matClear = new Material(shaderClear);
        matComposite = new Material(shaderComposite);
        matUpsample = new Material(shaderUpsample);
        matCubemap = new Material(shaderCubemap);
        matClear.hideFlags = HideFlags.HideAndDontSave;
        matComposite.hideFlags = HideFlags.HideAndDontSave;
        matUpsample.hideFlags = HideFlags.HideAndDontSave;
        matCubemap.hideFlags = HideFlags.HideAndDontSave;
        scaleId = Shader.PropertyToID("_Scale");
        frameId = Shader.PropertyToID("_OddEvenFrame");

        oldWidth = Screen.width;
        oldHeight = Screen.height;

        routine = StartCoroutine(EndOfFrame());
    }

    void OnDisable()
    {
        Camera.onPreCull -= PreCull;
        Camera.onPostRender -= PostRender;
        if (tex)
        {
            if (tex.IsCreated())
                tex.Release();
            DestroyImmediate(tex);
        }
        if (matClear)
            DestroyImmediate(matClear);
        if (matComposite)
            DestroyImmediate(matComposite);
        if (matUpsample)
            DestroyImmediate(matUpsample);
        StopCoroutine(routine);
    }

    public void Reinitialize()
    {
        if (tex)
        {
            if (tex.IsCreated())
                tex.Release();
            DestroyImmediate(tex);
        }
        enabled = res.force;
        if (!res.force)
            return;
        if (res.cubemap)
        {
            tex = new RenderTexture(res.cuberes, res.cuberes, 16);
            tex.isCubemap = true;
            tex.name = "CoarseFXCubemap";
        }
        else
        {
            tex = new RenderTexture(res.width, res.height, 16);
            tex.hideFlags = HideFlags.HideAndDontSave;
            tex.name = "CoarseFXBuffer";
        }
        tex.Create();
    }

    IEnumerator EndOfFrame()
    {
        while (true)
        {
            yield return new WaitForEndOfFrame();
            FinalBlit();
        }
    }
}