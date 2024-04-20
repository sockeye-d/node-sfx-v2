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

        private static readonly Dictionary<Filter, Func<float, float>> _filterFuncs = new()
        {
            [Filter.CONSTANT] = x => 1.0f,
            [Filter.BELL] = x => -64.0f * (3.0f * (MathF.Pow(x, 4) + MathF.Pow(x, 5)) + MathF.Pow(x, 3) + MathF.Pow(x, 6)),
            [Filter.TRIANGLE] = x => 1.0f - MathF.Abs(2.0f * x - 1.0f),
            [Filter.LINEAR_POSITIVE] = x => x + 1.0f,
            [Filter.LINEAR_NEGATIVE] = x => -x,
        };

        private Filter _filter;
        private readonly Queue<Vector2> _data = new();
        private int _queueLength = 0;
        public ConvolutionalLowPassNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            _queueLength = (int)(args[1].X * SampleRate);
            _data.Enqueue(args[0]);

            while (_data.Count > _queueLength)
            {
                _data.Dequeue();
            }

            IEnumerator<Vector2> enumerator = _data.GetEnumerator();

            float totalX = 0.0f;
            float totalY = 0.0f;
            float max = 0.0f;
            int i = 0;

            while (enumerator.MoveNext())
            {
                float weight = _filterFuncs[_filter]((float)i / _data.Count - 1.0f);
                totalX += enumerator.Current.X * weight;
                totalY += enumerator.Current.X * weight;
                max += weight;
                i++;
            }

            return _Mix(args[0], new Vector2(totalX, totalY) / max, args[2]);
        }

        protected override void _UpdateNodeArguments()
        {
            _filter = (Filter)Source.GetNode<OptionButton>("Filter").Selected;
        }
    }
}
