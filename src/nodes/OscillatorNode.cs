using Godot;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Runtime.CompilerServices;
using System.Text;

namespace NodeSfx.Nodes
{
    public class OscillatorNode : Node
    {

        public enum OscillatorType
        {
            SINE,
            SQUARE,
            TRIANGLE,
            SAWTOOTH,
            NOISE,
            SMOOTH_NOISE,
        }

        private double _time;

        private readonly ReadOnlyDictionary<OscillatorType, Func<double, double>> _functionMap = new(new Dictionary<OscillatorType, Func<double, double>>
        {
            [OscillatorType.SINE] = (time) => Math.Sin(Math.Tau * time),
            [OscillatorType.SQUARE] = (time) => 2.0 * Math.Floor(2.0 * (time % 1.0)) - 1.0,
            [OscillatorType.TRIANGLE] = (time) => 2.0 * Math.Abs(2.0 * (time % 1.0) - 1.0) - 1.0,
            [OscillatorType.SAWTOOTH] = (time) => 2.0 * (time % 1.0) - 1.0,
            [OscillatorType.NOISE] = (time) => _HashTime(time * 10000.0),
            [OscillatorType.SMOOTH_NOISE] = (time) => _SmoothNoise(time),
        });

        public OscillatorType Type;

        public OscillatorNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            _time += InvSampleRate * args[0].X;
            float valX = (float)_functionMap[Type](_time + args[2].X) * args[1].X;
            float valY = (float)_functionMap[Type](_time + args[3].X) * args[1].X;
            return new Vector2(valX, valY);
        }

        protected override void _UpdateNodeArguments()
        {
            Type = (OscillatorType)Source.GetNode<OptionButton>("TypeSelector").Selected;
        }

        private static double _HashTime(double time)
        {
            time = (time * .1031) % 1.0;
            time *= time + 33.33;
            time *= time + time;
            return (time % 1.0) * 2.0 - 1.0;
        }

        private static double _Smoothstep(double x)
        {
            return 3.0 * x * x - 2.0 * x * x * x;
        }

        private static double _SmoothNoise(double x)
        {
            double a = _HashTime(Math.Floor(x));
            double b = _HashTime(Math.Floor(x) + 1.0);
            double f = _Smoothstep(x % 1.0f);
            return _Mix(a, b, f);
        }
    }
}
