using UnityEngine;
using UnityEngine.Experimental.Rendering;

[ExecuteAlways, ImageEffectAllowedInSceneView]
public class PostProcessing2D : MonoBehaviour
{
    [SerializeField] GaussianBlur gaussianBlur;
    [SerializeField] bool useInSceneView;

    private RenderTexture target;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(useInSceneView || Camera.current.name != "SceneCamera")
        {
            SendParameters();
            Render(destination);
        }
        else
            Graphics.Blit(source, destination);
    }



    private void Render(RenderTexture destination)
    {
        InitializeRenderTexture();

        gaussianBlur.shader.SetTexture(0, "Result", target);

        uint kernelX, kernelY, kernelZ;
        gaussianBlur.shader.GetKernelThreadGroupSizes(0, out kernelX, out kernelY, out kernelZ);

        int threadGroupsX = Mathf.CeilToInt(target.width / (float)kernelX);
        int threadGroupsY = Mathf.CeilToInt(target.height / (float)kernelY);
        gaussianBlur.shader.Dispatch(0, threadGroupsX, threadGroupsY, 1);

        Graphics.Blit(target, destination);
    }
    private void InitializeRenderTexture()
    {
        int width = Screen.width;
        int height = Screen.height;

        if(target == null || target.width != width || target.height != height)
        {
            if (target != null)
                target.Release();

            target = new RenderTexture(width,
                height, 0,
                RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            target.enableRandomWrite = true;
            target.Create();
        }
    }
    private void SendParameters()
    {
        gaussianBlur.shader.SetFloat("_Directions", gaussianBlur.directions);
        gaussianBlur.shader.SetFloat("_Quality", gaussianBlur.quality);
        gaussianBlur.shader.SetFloat("_Size", gaussianBlur.size);
    }
}
