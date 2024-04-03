using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class ConvolutionalLowPassNode : Node
    {
        enum Filter
        {
            CONSTANT,
            BELL,
            TRIANGLE,
            LINEAR_POSITIVE,
            LINEAR_NEGATIVE,
        }

        enum PowerCurveSetting
        {
            IN,
            OUT,
            INOUT,
        }

        private static readonly Dictionary<Filter, Func<double, double>> _filterFuncs = new()
        {
            [Filter.CONSTANT] = x => 1.0,
            [Filter.BELL] = x => -64.0 * (3.0 * (Math.Pow(x, 4) + Math.Pow(x, 5)) + Math.Pow(x, 3) + Math.Pow(x, 6)),
            [Filter.TRIANGLE] = x => 1.0 - Math.Abs(2.0 * x - 1.0),
            [Filter.LINEAR_POSITIVE] = x => x + 1.0,
            [Filter.LINEAR_NEGATIVE] = x => -x,
        };

        private Filter _filter;
        private readonly Queue<float> _data = new();
        private int _queueLength = 0;
        public ConvolutionalLowPassNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            _queueLength = (int)(args[1] * SampleRate);
            _data.Enqueue((float)args[0]);

            while (_data.Count > _queueLength)
            {
                _data.Dequeue();
            }

            IEnumerator<float> enumerator = _data.GetEnumerator();

            double total = 0.0;
            double max = 0.0;
            int i = 0;

            while (enumerator.MoveNext())
            {
                double weight = _filterFuncs[_filter]((double)i / _data.Count - 1.0);
                total += enumerator.Current * weight;
                max += weight;
                i++;
            }

            return _Mix(args[0], total / max, args[2]);
        }

        protected override void _UpdateNodeArguments()
        {
            _filter = (Filter)Source.GetNode<OptionButton>("Filter").Selected;
        }
    }
}
