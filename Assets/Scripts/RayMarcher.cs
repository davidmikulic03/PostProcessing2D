using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RayMarcher : MonoBehaviour
{
    [SerializeField] private Material rayMarchingMaterial;
    void OnEnable()
    {
        Camera camera = Camera.main;
        rayMarchingMaterial.SetFloat("_FOV", camera.fieldOfView * Mathf.Deg2Rad);
        rayMarchingMaterial.SetFloat("_Aspect", camera.aspect);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!rayMarchingMaterial) {
            Graphics.Blit(source, destination);
            Debug.LogWarning("Ray Marching material not assigned.");
            return;
        }
        Graphics.Blit(source, destination, rayMarchingMaterial);
    }
}
