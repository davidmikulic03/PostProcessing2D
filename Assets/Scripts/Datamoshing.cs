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
    [SerializeField, Range(0f, 1f)] private float maxColorDifference = 0.1f; 
    [SerializeField, Range(0f, 1f)] private float spreadThreshold = 0.1f; 

    private Quaternion lastCameraRotation = Quaternion.identity;
    private RenderTexture target = null;
    private RenderTexture cleanRender = null;
    private RenderTexture refresher = null;

    private int transformKernel = 0;
    private int detransformKernel = 1;

    private bool initialized = false;

    private float[] dct = new[] {
        0.353553f,0.353553f,0.353553f,0.353553f,0.353553f,0.353553f,0.353553f,0.353553f ,
        0.490393f,0.415735f,0.277785f,0.0975452f,-0.0975452f,-0.277785f,-0.415735f,-0.490393f,
        0.46194f,0.191342f,-0.191342f,-0.46194f,-0.46194f,-0.191342f,0.191342f,0.46194f,
        0.415735f,-0.0975452f,-0.490393f,-0.277785f,0.277785f,0.490393f,0.0975452f,-0.415735f,
        0.353553f,-0.353553f,-0.353553f,0.353553f,0.353553f,-0.353553f,-0.353553f,0.353553f,
        0.277785f,-0.490393f,0.0975452f,0.415735f,-0.415735f,-0.0975452f,0.490393f,-0.277785f,
        0.191342f,-0.46194f,0.46194f,-0.191342f,-0.191342f,0.46194f,-0.46194f,0.191342f,
        0.0975452f,-0.277785f,0.415735f,-0.490393f,0.490393f,-0.415735f,0.277785f,-0.0975452f
    };

    private int[] quantizationMatrix = new[] {
        16, 11, 10, 16, 24, 40, 51, 60,
        12, 12, 14, 19, 26, 58, 60, 55,
        14, 13, 16, 24, 40, 57, 69, 56,
        14, 17, 22, 29, 51, 87, 80, 62,
        18, 22, 37, 56, 68, 109, 103, 77,
        24, 35, 55, 64, 81, 104, 113, 92,
        49, 64, 78, 87, 103, 121, 120, 101,
        72, 92, 95, 98, 112, 100, 103, 99
    };
    
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

    private void OnDisable()
    {
        target.Release();
        cleanRender.Release();
        refresher.Release();
    }

    private void Start()
    {
        Application.targetFrameRate = 0;
        Camera camera = Camera.main;
        dataMoshingShader.SetFloat("FOV", camera.fieldOfView * Mathf.Deg2Rad);
        dataMoshingShader.SetFloat("AspectRatio", camera.aspect);
        dataMoshingShader.SetFloat("RefreshProbability", refreshProbability);
        dataMoshingShader.SetFloat("MaxColorDifference", maxColorDifference);
        dataMoshingShader.SetFloat("SpreadThreshold", spreadThreshold);
        dataMoshingShader.SetFloats("dct", dct);
        dataMoshingShader.SetInts("quantizationMatrix", quantizationMatrix);

        transformKernel = dataMoshingShader.FindKernel("DCT");
        detransformKernel = dataMoshingShader.FindKernel("IDCT");
    }

    void Render(RenderTexture destination) {
        uint kernelX, kernelY, kernelZ;
        dataMoshingShader.GetKernelThreadGroupSizes(transformKernel, out kernelX, out kernelY, out kernelZ);

        int threadGroupsX = Mathf.CeilToInt(target.width / (float)kernelX);
        int threadGroupsY = Mathf.CeilToInt(target.height / (float)kernelY);
        dataMoshingShader.Dispatch(transformKernel, threadGroupsX, threadGroupsY, 1);
        dataMoshingShader.Dispatch(detransformKernel, threadGroupsX, threadGroupsY, 1);

        Graphics.Blit(cleanRender, destination);
    }

    void InitializeRenderTexture() {
        Vector2Int targetResolution = new Vector2Int((int)(baseResolution.x * resolution), (int)(baseResolution.y * resolution));

        if (!target || 
            target.width != targetResolution.x || 
            target.height != targetResolution.y) {

            if (target) {
                target.Release();
            }
            
            target = new RenderTexture(targetResolution.x, targetResolution.y, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            target.filterMode = FilterMode.Point;
            target.enableRandomWrite = true;
            target.Create();

            refresher = new RenderTexture(target);
            refresher.Create();
            cleanRender = new RenderTexture(target);
            cleanRender.Create();

            dataMoshingShader.SetTexture(transformKernel, "Result", target);
            dataMoshingShader.SetTexture(detransformKernel, "Result", target);
            dataMoshingShader.SetTexture(transformKernel, "Refresher", refresher);
            dataMoshingShader.SetTexture(detransformKernel, "CleanRender", cleanRender);
            dataMoshingShader.SetInt("ResolutionX", targetResolution.x + 1);
            dataMoshingShader.SetInt("ResolutionY", targetResolution.y + 1);
        }
    }

    void SendData()
    {
        Quaternion deltaRotation = Quaternion.Inverse(lastCameraRotation) * Camera.main.transform.rotation;
        
        dataMoshingShader.SetMatrix("DeltaTransform", Matrix4x4.TRS(Vector3.zero, deltaRotation, Vector3.one));
        //cleanRender.filterMode = FilterMode.Point;
        dataMoshingShader.SetTexture(transformKernel, "CleanRender", cleanRender);
        
        lastCameraRotation = Camera.main.transform.rotation;
    }
}
