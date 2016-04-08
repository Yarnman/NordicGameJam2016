using UnityEngine;
using UnityEngine.SceneManagement;

[ExecuteInEditMode]
#if UNITY_EDITOR
[UnityEditor.InitializeOnLoad]
#endif
public class CoarseFXQuality : MonoBehaviour
{
    [System.Serializable]
    public class Resolution
    {
        public Resolution(int width, int height, int cuberes, float imageAspect, float pixelAspect, bool progressive, bool lockImageAspect, bool lockPixelAspect, bool cubemap, bool antialias, bool force)
        {
            m_widthLocked = width;
            m_heightLocked = height;
            m_cuberes = cuberes;
            m_imageAspectLocked = imageAspect;
            m_pixelAspectLocked = pixelAspect;
            m_lockImageAspect = lockImageAspect;
            m_lockPixelAspect = lockPixelAspect;
            m_progressive = progressive;
            m_cubemap = cubemap;
            this.force = force;
            this.antialias = antialias;
        }

        [SerializeField] int m_width, m_widthLocked;
        public int width { get { return m_width; } }
        public int widthLocked {
            get { return m_widthLocked; }
            set { m_widthLocked = value;
                ScreenUpdate(); } }
        
        [SerializeField] int m_height, m_heightLocked;
        public int height { get { return m_height; } }
        public int heightLocked {
            get { return m_heightLocked; }
            set { m_heightLocked = value;
                ScreenUpdate(); } }

        [SerializeField] int m_cuberes;
        public int cuberes {
            get { return m_cuberes; }
            set { m_cuberes = value;
                ScreenUpdate(); } }

        [SerializeField] float m_imageAspect, m_imageAspectLocked;
        public float imageAspect { get { return m_imageAspect; } }
        public float imageAspectLocked {
            get { return m_imageAspectLocked; }
            set { m_imageAspectLocked = value;
                ScreenUpdate(); } }

        [SerializeField] float m_pixelAspect, m_pixelAspectLocked;
        public float pixelAspect { get { return m_pixelAspect; } }
        public float pixelAspectLocked {
            get { return m_pixelAspectLocked; }
            set { m_pixelAspectLocked = value;
                ScreenUpdate(); } }

        [SerializeField] bool m_lockImageAspect;
        public bool lockImageAspect {
            get { return m_lockImageAspect; }
            set { m_lockImageAspect = value;
                ScreenUpdate(); } }

        [SerializeField] bool m_lockPixelAspect;
        public bool lockPixelAspect {
            get { return m_lockPixelAspect; }
            set { m_lockPixelAspect = value;
                ScreenUpdate(); } }

        [SerializeField] bool m_usingComposite;
        public bool usingComposite { get { return m_usingComposite; } }
        
        [SerializeField] bool m_progressive;
        public bool progressive {
            get { return m_progressive; }
            set { m_progressive = value;
                ScreenUpdate(); } }
        
        [SerializeField] bool m_cubemap;
        public bool cubemap {
            get { return m_cubemap; }
            set { m_cubemap = value;
                ScreenUpdate(); } }

        public bool antialias, force;

        public void ScreenUpdate()
        {
            int width, height;
            GetUnityResolution(out width, out height);
            if (m_lockImageAspect && width > height * m_imageAspectLocked)
                width = Mathf.RoundToInt(height * m_imageAspectLocked);
            else if (m_lockImageAspect)
                height = Mathf.RoundToInt(width / m_imageAspectLocked);
            m_imageAspect = m_lockImageAspect ? imageAspectLocked : (float)width / height;
            m_height = Mathf.Min(height, m_heightLocked);
            m_width = Mathf.Min(width, m_lockPixelAspect ? Mathf.RoundToInt(m_height * m_imageAspect * m_pixelAspectLocked) : m_widthLocked);
            m_pixelAspect = m_lockPixelAspect ? pixelAspectLocked : (float)m_width / m_height / m_imageAspect;
        }

        void GetUnityResolution(out int width, out int height)
        {
#if UNITY_EDITOR
            string[] res = UnityEditor.UnityStats.screenRes.Split('x');
            width = int.Parse(res[0]);
            height = int.Parse(res[1]);
#else
        width = Screen.width;
        height = Screen.height;
#endif
        }
    }

    [SerializeField] Resolution m_resolution = new Resolution(640, 480, 256, 4f / 3f, 1f, true, false, false, false, true, true);
    public static Resolution resolution {
        get { return instance.m_resolution; }
        set { instance.m_resolution = value; }
    }

    [SerializeField] Vector4 m_colQuant = new Vector4(255f, 255f, 255f, 255f);
    public static Vector4 colQuant {
        get { return instance.m_colQuant; }
        set { instance.m_colQuant = value; } }

    [SerializeField] Texture2D m_ditherTex;
    public static Texture2D ditherTex {
        get { return instance.m_ditherTex; }
        set { instance.m_ditherTex = value; } }

    [SerializeField] Vector2 m_vertQuant = new Vector2(256f, 256f);
    public static Vector2 vertQuant {
        get { return instance.m_vertQuant * 2f; }
        set { instance.m_vertQuant = value / 2f; } }

    [SerializeField] Vector2 m_perspCorr = Vector2.zero;
    public static Vector2 perspCorr {
        get { return instance.m_perspCorr / 8f; }
        set { instance.m_perspCorr = value * 8f; } }

    [SerializeField] int m_targetFrameRate;
    public static int targetFrameRate {
        get { return instance.m_targetFrameRate; }
        set { instance.m_targetFrameRate = value; } }

    [SerializeField] bool m_posterize;
    public static bool posterize {
        get { return instance.m_posterize; }
        set { instance.m_posterize = value; } }

    [SerializeField] bool m_dither;
    public static bool dither {
        get { return instance.m_dither; }
        set { instance.m_dither = value; } }

    [SerializeField] bool m_wobble;
    public static bool wobble {
        get { return instance.m_wobble; }
        set { instance.m_wobble = value; } }

    [SerializeField] bool m_perspectiveCorrection;
    public static bool perspectiveCorrection {
        get { return instance.m_perspectiveCorrection; }
        set { instance.m_perspectiveCorrection = value; } }

    [SerializeField] bool m_limitFrameRate;
    public static bool limitFrameRate {
        get { return instance.m_limitFrameRate; }
        set { instance.m_limitFrameRate = value; } }

    static CoarseFXQuality instance;

    static int ditherId, colorId, colorInvId, vertexId, perspCorrId, perspCorrBiasId;
#if UNITY_EDITOR
    public static void SetDirty()
    {
        UnityEditor.EditorUtility.SetDirty(instance);
        UnityEditor.SceneManagement.EditorSceneManager.MarkAllScenesDirty();
    }
#endif

    CoarseFXQuality()
    {
        instance = this;
    }

    void OnEnable()
    {
        Camera.onPreRender += UpdatePerCameraProperties;
        colorId = Shader.PropertyToID("_ColorQuantize");
        colorInvId = Shader.PropertyToID("_ColorQuantizeInv");
        ditherId = Shader.PropertyToID("_DitherTex");
        vertexId = Shader.PropertyToID("_VertexQuantize");
        perspCorrId = Shader.PropertyToID("_PerspCor");

        UpdateProperties();
    }

    void OnDisable()
    {
        Camera.onPreRender -= UpdatePerCameraProperties;
    }

    public static void UpdateProperties()
    {
        instance.UpdateProperties_Internal();
    }

    void UpdateProperties_Internal()
    {
        Shader.SetGlobalVector(colorId, posterize ? colQuant : Vector4.zero);
        Shader.SetGlobalVector(colorInvId, posterize ? new Vector4(1f / colQuant.x, 1f / colQuant.y, 1f / colQuant.z, 1f / colQuant.w) : Vector4.zero);
        Shader.SetGlobalTexture(ditherId, dither ? ditherTex : Texture2D.whiteTexture);
        Shader.SetGlobalVector(vertexId, wobble ? new Vector4(m_vertQuant.x, m_vertQuant.y, 1f / m_vertQuant.x, 1f / m_vertQuant.y) : Vector4.zero);
        Shader.SetGlobalVector(perspCorrId, perspectiveCorrection ? m_perspCorr : Vector2.zero);
        Application.targetFrameRate = limitFrameRate ? targetFrameRate : -1;
    }

    void UpdatePerCameraProperties(Camera cam)
    {
        if (!resolution.progressive && cam.cameraType == CameraType.Game && cam.name != "Preview Camera")
        {
            Matrix4x4 proj = cam.projectionMatrix;
            Shader.SetGlobalVector("_DitherTex_ScaleOfs", new Vector4(ditherTex.texelSize.x, ditherTex.texelSize.y * 2f, 0f, proj.m12 * cam.pixelHeight * ditherTex.texelSize.y));
        }
        else
            Shader.SetGlobalVector("_DitherTex_ScaleOfs", ditherTex.texelSize);
    }

#if UNITY_EDITOR
    static Scene scene;

    static CoarseFXQuality()
    {
        UnityEditor.EditorApplication.update += ApplicationUpdate;
    }

    static void ApplicationUpdate()
    {
        if (scene.isLoaded)
            return;

        scene = SceneManager.GetActiveScene();

        CoarseFXQuality settings = FindObjectOfType<CoarseFXQuality>();
        if (settings)
        {
            settings.gameObject.hideFlags = HideFlags.None;
            return;
        }

        GameObject go = new GameObject("CoarseFXQuality", typeof(CoarseFXQuality));
        go.hideFlags = HideFlags.HideInHierarchy;
    }
#endif
}