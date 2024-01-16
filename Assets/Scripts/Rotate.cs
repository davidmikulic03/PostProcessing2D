using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    [SerializeField, Range(0f, 10f)] private float rotationTime = 1.0f;
    [SerializeField] private Vector3 axis = Vector3.up;
    
    void Update()
    {
        transform.rotation = Quaternion.AngleAxis(360 * Time.deltaTime / rotationTime, axis) * transform.rotation;
    }
}
