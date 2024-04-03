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

        protected override double Calculate(double[] args)
        {
            double time = args[0];
            double fromMin = args[1];
            double fromMax = args[2];
            double toMin = args[3];
            double toMax = args[4];
            if (Input.IsKeyPressed(Key.S))
            {
                GD.Print(_points.Stringify());
            }
            return _Remap(_GetValue(_Remap(time, fromMin, fromMax, 0.0, 1.0)), 0.0, 1.0, toMin, toMax);
        }

        protected override void _UpdateNodeArguments()
        {
            _points = (Vector2[])Source.Get("normalized_points");
        }

        private double _GetValue(double x)
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
