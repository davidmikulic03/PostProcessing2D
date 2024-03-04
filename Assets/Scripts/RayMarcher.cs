using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RayMarcher : MonoBehaviour
{
    [SerializeField] private Material rayMarchingMaterial;

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
