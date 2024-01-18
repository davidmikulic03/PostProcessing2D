using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class FaceCamera : MonoBehaviour
{
    private void OnWillRenderObject()
    {
        Vector3 toCamera = transform.position - Camera.current.transform.position;
        transform.rotation = Quaternion.LookRotation(toCamera);
    }
}
