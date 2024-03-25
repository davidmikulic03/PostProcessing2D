using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Serialization;

[ExecuteInEditMode]
public class TerrainGen : MonoBehaviour
{
    [Header("Heterogeneous Terrain")]
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private Shader shader;
    [SerializeField, Range(1, 8192)] private int resolution = 2048;
    [SerializeField, Range(0f, 32f)] private float scale = 2f;
    [SerializeField, Range(1, 16)] private int depth = 2;
    [SerializeField, Range(0f, 4f)] private float fractalDimension = 2f;
    [SerializeField, Range(0f, 4f)] private float lacunarity = 2f;
    [SerializeField, Range(0f, 2f)] private float seaLevel = 0.5f;
    [Header("Craters")]
    [SerializeField, Range(0f, 16f)] private float craterScale = 8f;
    [SerializeField, Range(0f, 4f)] private float craterDimension = 2f;
    [SerializeField, Range(0f, 4f)] private float craterLacunarity = 2f;
    [SerializeField, Range(0f, 1f)] private float craterSize = 0.5f;
    [SerializeField, Range(0f, 4f)] private float craterAmplitude = 2f;
    [SerializeField, Range(0f, 4f)] private float craterNoise = 8f;
    [SerializeField, Range(0, 8)] private int craterOctaves = 3;
    [Header("Extra")]
    [SerializeField] private Vector3 offset = Vector3.zero;
    [SerializeField, Range(0f, 4f)] private float height = 1f;
    
    
    private RenderTexture heightMap = null;
    private RenderTexture normalMap = null;
    private RenderTexture flowMap = null;

    private int baseKernel = 0;
    private int normalsKernel = 1;
    private int fluvialKernel = 2;
    
    private MeshRenderer meshRendererComp = null;

    private void OnEnable() {
        GenerateHeight();
    }

    private void OnValidate() {
        GenerateHeight();
    }

    private void OnDisable() {
        if(heightMap)
            heightMap.Release();
    }

    private void InitializeComputeShader() {
        InitializeRenderTextures();
        
        baseKernel = computeShader.FindKernel("BaseGen");
        normalsKernel = computeShader.FindKernel("NormalsGen");
        fluvialKernel = computeShader.FindKernel("FluvialFilter");
        
        computeShader.SetFloat("Scale", scale);
        computeShader.SetInt("Depth", depth);
        computeShader.SetFloat("Dimension", fractalDimension);
        computeShader.SetFloat("Lacunarity", lacunarity);
        computeShader.SetFloat("SeaLevel", seaLevel);
        computeShader.SetVector("Offset", offset);
        computeShader.SetInt("Resolution", resolution);
        computeShader.SetFloat("Height", height);
        
        computeShader.SetFloat("CraterScale", craterScale);
        computeShader.SetFloat("CraterLacunarity", craterLacunarity);
        computeShader.SetFloat("CraterDimension", craterDimension);
        computeShader.SetFloat("CraterSize", craterSize);
        computeShader.SetFloat("CraterNoise", craterNoise);
        computeShader.SetFloat("CraterAmplitude", craterAmplitude);
        computeShader.SetInt("CraterOctaves", craterOctaves);
        
        computeShader.SetTexture(baseKernel,"HeightMap", heightMap);
        computeShader.SetTexture(normalsKernel,"HeightMap", heightMap);
        
        computeShader.SetTexture(fluvialKernel,"HeightMap", heightMap);
        computeShader.SetTexture(fluvialKernel,"FlowMap", flowMap);
        
        computeShader.SetTexture(normalsKernel,"NormalMap", normalMap);
        computeShader.SetTexture(fluvialKernel,"NormalMap", normalMap);
    }

    private void InitializeRenderTextures() {
        if (!heightMap || 
            heightMap.height != resolution || 
            heightMap.width != resolution) {

            if (heightMap) {
                heightMap.Release();
            }

            heightMap = new RenderTexture(resolution, resolution, 0, RenderTextureFormat.ARGBFloat);
            heightMap.enableRandomWrite = true;
            
            normalMap = new RenderTexture(heightMap);
            flowMap = new RenderTexture(heightMap);
            
            heightMap.Create();
            normalMap.Create();
            flowMap.Create();
        }
    }

    public void GenerateHeight() {
        if (!computeShader)
            return;
        
        baseKernel = computeShader.FindKernel("BaseGen");
        normalsKernel = computeShader.FindKernel("NormalsGen");
        
        InitializeComputeShader();
        computeShader.GetKernelThreadGroupSizes(baseKernel, out uint x, out uint y, out _);
        
        computeShader.Dispatch(baseKernel, resolution / (int)x, resolution / (int)y, 1);
        computeShader.Dispatch(normalsKernel, resolution / (int)x, resolution / (int)y, 1);

        if (!meshRendererComp)
            meshRendererComp = GetComponent<MeshRenderer>();
        Material material = new Material(shader);
        material.SetTexture("_HeightMap", heightMap);
        material.SetTexture("_NormalMap", normalMap);
        material.SetFloat("_Height", height);

        meshRendererComp.material = material;
    }

    public void Erode()
    {
        if (!computeShader)
            return;
        
        fluvialKernel = computeShader.FindKernel("FluvialFilter");
        normalsKernel = computeShader.FindKernel("NormalsGen");
        
        InitializeComputeShader();
        computeShader.GetKernelThreadGroupSizes(fluvialKernel, out uint x, out uint y, out _);
        
        computeShader.Dispatch(fluvialKernel, resolution / (int)x, resolution / (int)y, 1);
        computeShader.Dispatch(normalsKernel, resolution / (int)x, resolution / (int)y, 1);

        if (!meshRendererComp)
            meshRendererComp = GetComponent<MeshRenderer>();
        Material material = new Material(shader);
        material.SetTexture("_HeightMap", heightMap);
        material.SetTexture("_NormalMap", normalMap);
        material.SetTexture("_FlowMap", flowMap);

        meshRendererComp.material = material;
    }
}

#if UNITY_EDITOR

[CustomEditor(typeof(TerrainGen))]
public class TerrainGUI : Editor
{
    private void OnSceneGUI()
    {
        
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Erode"))
        {
            var terrain = (TerrainGen)target;
            terrain.Erode();
        }
    }
}

#endif