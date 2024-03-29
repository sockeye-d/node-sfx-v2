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

        private Dictionary<OscillatorType, Func<double, double, double, double, double>> _functionMap = new()
        {
            [OscillatorType.SINE] = (time, freq, amp, phase) => Math.Sin(Math.Tau * (time * freq + phase)) * amp,
            [OscillatorType.SQUARE] = (time, freq, amp, phase) => (2.0 * (((time * freq) + phase) % 1.0) - 1.0) * amp,
            [OscillatorType.TRIANGLE] = (time, freq, amp, phase) => (2.0 * ((time * freq) + phase) % 1.0 - 1.0) * amp,
            [OscillatorType.NOISE] = (time, freq, amp, phase) => _HashTime(time * 10000.0) * amp,
            [OscillatorType.SMOOTH_NOISE] = (time, freq, amp, phase) => _Mix(_HashTime(Math.Floor((time * freq) + phase)), _HashTime(Math.Floor((time * freq) + phase) + 1.0), _Smoothstep(time % 1.0)) * amp,
        };

        public OscillatorType Type;

        public OscillatorNode(double[] arguments, string name, OscillatorType type) : base(arguments, name)
        {
            Type = type;
        }

        protected override double Calculate(double[] args)
        {
            _time += Node.InvSampleRate;
            return _functionMap[Type](Node.Time, args[0], args[1], args[2]);
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
    }
}
