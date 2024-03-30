using Godot;
using System;
using System.Collections.Generic;
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
            NOISE,
            SMOOTH_NOISE,
        }

        private double _time;

        private Dictionary<OscillatorType, Func<double, double, double, double>> _functionMap = new()
        {
            [OscillatorType.SINE] = (time, amp, phase) => Math.Sin(Math.Tau * (time + phase)) * amp,
            [OscillatorType.SQUARE] = (time, amp, phase) => (2.0 * Math.Floor(2.0 * ((time + phase) % 1.0)) - 1.0) * amp,
            [OscillatorType.TRIANGLE] = (time, amp, phase) => (2.0 * ((time + phase) % 1.0) - 1.0) * amp,
            [OscillatorType.NOISE] = (time, amp, phase) => _HashTime(time * 10000.0) * amp,
            [OscillatorType.SMOOTH_NOISE] = (time, amp, phase) =>_SmoothNoise(time + phase) * amp,
        };

        public OscillatorType Type;

        public OscillatorNode(GraphNode source, string name, OscillatorType type) : base(source, name)
        {
            Type = type;
        }

        protected override double Calculate(double[] args)
        {
            _time += InvSampleRate * args[0];
            return _functionMap[Type](_time, args[1], args[2]);
        }

        protected override void _UpdateNodeArguments()
        {
            Type = (OscillatorType)Source.GetNode<OptionButton>("TypeSelector").Selected;
        }

        private static double _Mix(double a, double b, double fac)
        {
            return a + (b - a) * fac;
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
            double f = _Smoothstep(x % 1.0);
            return _Mix(a, b, f);
        }
    }
}
