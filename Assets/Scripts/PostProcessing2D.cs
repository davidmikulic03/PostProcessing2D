using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteAlways, ImageEffectAllowedInSceneView, RequireComponent(typeof(Camera))]
public class PostProcessing2D : MonoBehaviour
{
    [SerializeField] Material material;
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
            material.SetVector("_AspectRatioMultiplier", aspectRatioData);
            Graphics.Blit(source, destination, material);
        }
        else
            Graphics.Blit(source, destination);
    }
}
