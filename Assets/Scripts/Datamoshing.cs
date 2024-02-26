using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class Datamoshing : MonoBehaviour
{
    [SerializeField] private ComputeShader dataMoshingShader;
    [SerializeField] private Vector2Int baseResolution = new Vector2Int(1920, 1080);
    [SerializeField, Range(0f, 1f)] private float resolution = 1f; 
    [SerializeField, Range(0f, 1f)] private float refreshProbability = 0.01f; 

    private Quaternion lastCameraRotation = Quaternion.identity;
    private RenderTexture target = null;
    private RenderTexture cleanRender = null;

    private int mainKernel = 0;

    private bool initialized = false;
    
    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (!dataMoshingShader) {
            Graphics.Blit(source, destination);
        } else {
            InitializeRenderTexture();
            Graphics.Blit(source, cleanRender);
            SendData();
            Render(destination);
            if (!initialized) {
                Graphics.Blit(cleanRender, target);
                initialized = true;
            }
        }
    }

    private void Update()
    {
        dataMoshingShader.SetFloat("Time", Time.time);
        
    }

    private void Awake()
    {
        Camera camera = Camera.main;
        dataMoshingShader.SetFloat("FOV", camera.fieldOfView * Mathf.Deg2Rad);
        dataMoshingShader.SetFloat("AspectRatio", camera.aspect);
        dataMoshingShader.SetFloat("RefreshProbability", refreshProbability);
    }

    void Render(RenderTexture destination) {
        uint kernelX, kernelY, kernelZ;
        dataMoshingShader.GetKernelThreadGroupSizes(mainKernel, out kernelX, out kernelY, out kernelZ);

        int threadGroupsX = Mathf.CeilToInt(target.width / (float)kernelX);
        int threadGroupsY = Mathf.CeilToInt(target.height / (float)kernelY);
        dataMoshingShader.Dispatch(mainKernel, threadGroupsX, threadGroupsY, 1);

        Graphics.Blit(target, destination);
    }

    void InitializeRenderTexture() {
        Vector2Int targetResolution = new Vector2Int((int)(baseResolution.x * resolution), (int)(baseResolution.y * resolution));

        if (!target || 
            target.width != targetResolution.x || 
            target.height != targetResolution.y) {

            if (target)
            {
                target.Release();
            }
            
            target = new RenderTexture(targetResolution.x, targetResolution.y, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            target.filterMode = FilterMode.Point;
            target.enableRandomWrite = true;
            target.Create();

            dataMoshingShader.SetTexture(mainKernel, "Result", target);
            dataMoshingShader.SetInt("ResolutionX", targetResolution.x + 1);
            dataMoshingShader.SetInt("ResolutionY", targetResolution.y + 1);
        }
        
        if (!cleanRender || 
            cleanRender.width != targetResolution.x || 
            cleanRender.height != targetResolution.y) {

            if (cleanRender)
            {
                cleanRender.Release();
            }
            
            cleanRender = new RenderTexture(targetResolution.x, targetResolution.y, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            cleanRender.filterMode = FilterMode.Point;
            cleanRender.enableRandomWrite = true;
            cleanRender.Create();

            dataMoshingShader.SetTexture(mainKernel, "CleanRender", cleanRender);
        }
    }

    void SendData()
    {
        Quaternion deltaRotation = Quaternion.Inverse(lastCameraRotation) * Camera.main.transform.rotation;
        
        dataMoshingShader.SetMatrix("DeltaTransform", Matrix4x4.TRS(Vector3.zero, deltaRotation, Vector3.one));
        dataMoshingShader.SetTexture(mainKernel, "CleanRender", cleanRender);
        
        lastCameraRotation = Camera.main.transform.rotation;
    }
}
