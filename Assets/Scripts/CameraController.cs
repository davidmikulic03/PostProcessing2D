using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    [SerializeField] private float panSpeed = 5;


    // Update is called once per frame
    void Update()
    {
        Vector2 input2D = GetInput();

        Quaternion currentRotation = transform.rotation;
        currentRotation = Quaternion.AngleAxis(input2D.x * panSpeed * Time.deltaTime,  Vector3.up) * currentRotation;
        currentRotation = Quaternion.AngleAxis(input2D.y * panSpeed * Time.deltaTime,  -transform.right) * currentRotation;
        transform.rotation = currentRotation;
    }

    Vector2 GetInput()
    {
        Vector2 input = Vector2.zero;
        if (Input.GetKey(KeyCode.A))
            input.x--;
        if (Input.GetKey(KeyCode.D))
            input.x++;
        if (Input.GetKey(KeyCode.W))
            input.y++;
        if (Input.GetKey(KeyCode.S))
            input.y--;
        return input.normalized;
    }
}
