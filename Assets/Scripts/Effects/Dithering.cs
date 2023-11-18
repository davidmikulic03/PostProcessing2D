using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class Dithering
{
    public Material material;
    [Range(1, 1080)] public int pixelDensity = 80;
    [Range(1, 255)] public int colors;

}
