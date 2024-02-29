using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Serialization;

public class CompressionPP : MonoBehaviour
{
    public enum Resolution {
        FHD1080 = 0,
        HD720,
        SD480,
        LD144,
        LD72
    }
    
    [SerializeField] private ComputeShader compressionShader;
    [SerializeField] private Resolution resolution;
    [SerializeField] private FilterMode filterMode = FilterMode.Point;
    [SerializeField, Range(0f, 1f)] private float noiseAmount = 0.01f; 
    [SerializeField, Range(0, 256)] private int quantizationAmount = 16; 
    
    private Quaternion lastCameraRotation = Quaternion.identity;
    private RenderTexture dctTarget = null;
    private RenderTexture idctTarget = null;
    private RenderTexture cleanRender = null;

    private int transformKernel = 0;
    private int detransformKernel = 1;

    private bool initialized = false;

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
        if (!compressionShader) {
            Graphics.Blit(source, destination);
            
        } else {
            InitializeRenderTexture();
            Graphics.Blit(source, cleanRender);
            Render(destination);
            if (!initialized) {
                Graphics.Blit(idctTarget, dctTarget);
                initialized = true;
            }
        }
    }

    private void Update() {
        compressionShader.SetFloat("Time", Time.time);
    }

    private void OnDisable()
    {
        dctTarget.Release();
        idctTarget.Release();
        cleanRender.Release();
    }

    private void OnEnable() {
        SendData();
        SetFilterMode();
        
        Camera camera = Camera.main;
        compressionShader.SetInts("quantizationMatrix", quantizationMatrix);

        transformKernel = compressionShader.FindKernel("DCT");
        detransformKernel = compressionShader.FindKernel("IDCT");
    }

    void Render(RenderTexture destination) {
        uint kernelX, kernelY, kernelZ;
        compressionShader.GetKernelThreadGroupSizes(transformKernel, out kernelX, out kernelY, out kernelZ);

        int threadGroupsX = Mathf.CeilToInt(dctTarget.width / (float)kernelX);
        int threadGroupsY = Mathf.CeilToInt(dctTarget.height / (float)kernelY);
        compressionShader.Dispatch(transformKernel, threadGroupsX, threadGroupsY, 1);
        compressionShader.Dispatch(detransformKernel, threadGroupsX, threadGroupsY, 1);

        Graphics.Blit(idctTarget, destination);
    }

    private void OnValidate() {
        SendData();
        SetFilterMode();
    }

    void InitializeRenderTexture() {
        Vector2Int targetResolution;
        switch (resolution) {
            case Resolution.FHD1080:
                targetResolution = new Vector2Int((int)(1920), (int)(1080));
                break;
            case Resolution.HD720:
                targetResolution = new Vector2Int((int)(1280), (int)(720));
                break;
            case Resolution.SD480:
                targetResolution = new Vector2Int((int)(854), (int)(480));
                break;
            case Resolution.LD144:
                targetResolution = new Vector2Int((int)(256), (int)(144));
                break;
            case Resolution.LD72:
                targetResolution = new Vector2Int((int)(128), (int)(72));
                break;
            default: 
                targetResolution = new Vector2Int((int)(1920), (int)(1080));
                break;
        }

        if (!cleanRender || 
            cleanRender.width != targetResolution.x || 
            cleanRender.height != targetResolution.y) {

            if (cleanRender) {
                cleanRender.Release();
            }
            
            cleanRender = new RenderTexture(targetResolution.x, targetResolution.y, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            cleanRender.enableRandomWrite = true;
            cleanRender.Create();

            idctTarget = new RenderTexture(cleanRender);
            dctTarget = new RenderTexture(cleanRender);
            idctTarget.Create();
            dctTarget.Create();

            compressionShader.SetTexture(transformKernel, "DCTSampler", dctTarget);
            compressionShader.SetTexture(transformKernel, "IDCTSampler", idctTarget);
            compressionShader.SetTexture(transformKernel, "CleanRender", cleanRender);
            compressionShader.SetTexture(detransformKernel, "DCTSampler", dctTarget);
            compressionShader.SetTexture(detransformKernel, "IDCTSampler", idctTarget);
            compressionShader.SetTexture(detransformKernel, "CleanRender", cleanRender);
            compressionShader.SetInt("ResolutionX", targetResolution.x);
            compressionShader.SetInt("ResolutionY", targetResolution.y);
        }
    }

    void SetFilterMode() {
        if(cleanRender)
            cleanRender.filterMode = filterMode;
        if(dctTarget)
            dctTarget.filterMode = filterMode;
        if(idctTarget)
            idctTarget.filterMode = filterMode;
    }

    void SendData() {
        compressionShader.SetFloat("NoiseAmount", noiseAmount);
        compressionShader.SetInt("QuantizationAmount", quantizationAmount);
    }
}
