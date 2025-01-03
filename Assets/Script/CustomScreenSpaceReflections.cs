using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[System.Serializable]
[PostProcess(typeof(CustomScreenSpaceReflectionsRenderer), PostProcessEvent.BeforeStack, "Custom/CustomSSR")]

public sealed class CustomScreenSpaceReflections : PostProcessEffectSettings
{

}

public sealed class CustomScreenSpaceReflectionsRenderer : PostProcessEffectRenderer<CustomScreenSpaceReflections>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Custom/CustomSSR"));
        sheet.properties.SetMatrix("_InverseView", context.camera.cameraToWorldMatrix);
        sheet.properties.SetMatrix("_ViewProjectionMatrix", context.camera.nonJitteredProjectionMatrix * context.camera.worldToCameraMatrix);
        context.command.BlitFullscreenTriangle(context.source, context.destination,sheet,0);
    }
}