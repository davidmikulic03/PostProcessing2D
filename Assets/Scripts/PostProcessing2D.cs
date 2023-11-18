using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteAlways, ImageEffectAllowedInSceneView]
public class PostProcessing2D : MonoBehaviour
{
    [SerializeField] Dithering dithering;
    [SerializeField] bool useInSceneView;

    private RenderTexture target;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (useInSceneView || Camera.current.name != "SceneCamera")
        {
            Vector2 aspectRatioData;
            if (Screen.height > Screen.width)
                aspectRatioData = new Vector2((float)Screen.width / Screen.height, 1);
            else
                aspectRatioData = new Vector2(1, (float)Screen.height / Screen.width);
            dithering.material.SetVector("_AspectRatioMultiplier", aspectRatioData);
            dithering.material.SetInt("_PixelDensity", dithering.pixelDensity);
            dithering.material.SetInt("_NumColors", dithering.colors);
            Graphics.Blit(source, destination, dithering.material);
        }
        else
            Graphics.Blit(source, destination);
    }
}
