using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class GaussianBlur
{
    public ComputeShader shader;
    [Range(0, 16)] public int directions = 16;
    [Range(0f, 4f)] public float quality = 3;
    public float size = 8;

}
