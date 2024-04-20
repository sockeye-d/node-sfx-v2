using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class AutomatorNode : Node
    {
        private Vector2[] _points;
        public AutomatorNode(GraphNode source, string name) : base(source, name)
        {
            _points = (Vector2[])Source.Get("normalized_points");
        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            Vector2 time = args[0];
            Vector2 fromMin = args[1];
            Vector2 fromMax = args[2];
            Vector2 toMin = args[3];
            Vector2 toMax = args[4];

            float x = _Remap(_GetValue(_Remap(time.X, fromMin.X, fromMax.X, 0.0f, 1.0f)), 0.0f, 1.0f, toMin.X, toMax.X);
            float y = _Remap(_GetValue(_Remap(time.Y, fromMin.Y, fromMax.Y, 0.0f, 1.0f)), 0.0f, 1.0f, toMin.Y, toMax.Y);

            return new Vector2(x, y);
        }

        protected override void _UpdateNodeArguments()
        {
            _points = Source.Get("normalized_points").AsVector2Array();
        }

        private float _GetValue(float x)
        {
            if (_points.Length == 1)
            {
                return _points[0].Y;
            }

            if (x <= _points[0].X)
            {
                return _points[0].Y;
            }

            if (x >= _points[^1].X)
            {
                return _points[^1].Y;
            }

            int i = 0;
            for (; i < _points.Length; i++)
            {
                if (_points[i].X > x)
                {
                    break;
                }
            }

            return _Remap(x, _points[i - 1].X, _points[i].X, _points[i - 1].Y, _points[i].Y);
        }
    }
}
