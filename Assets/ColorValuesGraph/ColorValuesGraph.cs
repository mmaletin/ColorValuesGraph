
using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(ColorValuesGraphRenderer), PostProcessEvent.AfterStack, "Debug/Color values graph")]
public class ColorValuesGraph : PostProcessEffectSettings
{
    [Tooltip("Set this parameter to false if shader you're debugging outputs values that aren't colors (normals, positions etc).")]
    public BoolParameter isColor = new BoolParameter { value = true };

    [Range(0f, 1f)] public FloatParameter samplingHeight = new FloatParameter { value = .5f };
    [Range(0f, 1f)] public FloatParameter scale = new FloatParameter { value = .9f };

    public FloatParameter signalScale = new FloatParameter { value = 1 };

    public ColorParameter samplingHeightColor = new ColorParameter { value = Color.gray };
    public ColorParameter unitLinesColor = new ColorParameter { value = Color.white };
}

public class ColorValuesGraphRenderer : PostProcessEffectRenderer<ColorValuesGraph>
{
    private static readonly int _IsColor = Shader.PropertyToID(nameof(_IsColor));
    private static readonly int _LineScale = Shader.PropertyToID(nameof(_LineScale));
    private static readonly int _SamplingHeight = Shader.PropertyToID(nameof(_SamplingHeight));
    private static readonly int _SamplingHeightColor = Shader.PropertyToID(nameof(_SamplingHeightColor));
    private static readonly int _UnitLinesColor = Shader.PropertyToID(nameof(_UnitLinesColor));
    private static readonly int _SignalScale = Shader.PropertyToID(nameof(_SignalScale));

    private Shader graphShader;

    public override void Init()
    {
        graphShader = Shader.Find("Hidden/Custom/ColorValuesGraph");
        base.Init();
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(graphShader);

        sheet.properties.SetFloat(_IsColor, settings.isColor ? 1 : 0);
        sheet.properties.SetFloat(_LineScale, settings.scale);
        sheet.properties.SetFloat(_SamplingHeight, settings.samplingHeight);
        sheet.properties.SetFloat(_SignalScale, settings.signalScale);

        sheet.properties.SetColor(_SamplingHeightColor, settings.samplingHeightColor);
        sheet.properties.SetColor(_UnitLinesColor, settings.unitLinesColor);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}