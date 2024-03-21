using System;
using UnityEngine;
using UnityEditor;
using UnityEngine.Serialization;

[ExecuteInEditMode]
public class TerrainGen : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private Shader shader;
    [SerializeField, Range(1, 8192)] private int resolution = 2048;
    [SerializeField, Range(0f, 32f)] private float scale = 2f;
    [SerializeField, Range(0, 16)] private int depth = 2;
    [SerializeField, Range(0f, 4f)] private float dimension = 2f;
    [SerializeField] private Vector3 offset = Vector3.zero;
    [SerializeField] private RenderTexture heightMap = null;

    private int baseKernel = 0;
    private MeshRenderer meshRendererComp = null;

    private void Awake()
    {
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
        computeShader.SetFloat("Scale", scale);
        computeShader.SetInt("Depth", depth);
        computeShader.SetFloat("Dimension", dimension);
        computeShader.SetVector("Offset", offset);
        computeShader.SetInt("Resolution", resolution);
        computeShader.SetTexture(baseKernel,"HeightMap", heightMap);
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
            heightMap.Create();
        }
    }

    public void GenerateHeight() {
        if (!computeShader)
            return;
        
        baseKernel = computeShader.FindKernel("BaseGen");
        InitializeComputeShader();
        computeShader.GetKernelThreadGroupSizes(baseKernel, out uint x, out uint y, out _);
        
        computeShader.Dispatch(baseKernel, resolution / (int)x, resolution / (int)y, 1);

        if (!meshRendererComp)
            meshRendererComp = GetComponent<MeshRenderer>();
        Material material = new Material(shader);
        material.SetTexture("_HeightMap", heightMap);

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
            //terrain.GenerateHeight();
        }
    }
}

#endif