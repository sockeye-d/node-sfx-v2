using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class ExponentialLowPassNode : Node
    {
        private float _valueX;
        private float _valueY;
        public ExponentialLowPassNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            _valueX += (args[0].X - _valueX) * (1.0f - MathF.Pow(args[1].X, 0.01f));
            _valueY += (args[0].Y - _valueY) * (1.0f - MathF.Pow(args[1].Y, 0.01f));
            return _Mix(args[0], new Vector2(_valueX, _valueY), args[2]);
        }
    }
}
