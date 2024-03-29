using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class OscilloscopeNode : Node
    {
        private Control _surface;
        private int _queueLength;
        private float _scale;
        private float _offset;
        private Queue<float> _queue;
        public OscilloscopeNode(double[] arguments, string name, Control surface) : base(arguments, name)
        {
            _surface = surface;
            _surface.Draw += _Draw;
            _queue = new Queue<float>();
        }

        protected override double Calculate(double[] args)
        {
            _queueLength = (int)args[1];
            _offset = (float)args[2];
            _scale = (float)args[3];

            _queue.Enqueue((float)args[0]);

            while (_queue.Count > _queueLength)
            {
                _queue.Dequeue();
            }

            return args[0];
        }

        private void _Draw()
        {
            if (_queue.Count > 1)
            {
                Vector2[] points = new Vector2[_queue.Count];
                int i = 0;
                foreach (float value in _queue)
                {
                    float x = i / (_queue.Count - 1.0f);
                    float y = value * _scale + _offset;
                    y = Math.Clamp(y, 0.0f, 1.0f);
                    points[i] = new Vector2(x, y) * _surface.GetRect().Abs().Size;
                    i++;
                }

                _surface.DrawPolyline(points, new Color(0.2f, 1.0f, 0.3f));
            }
        }

        public override void Dispose()
        {
            base.Dispose();
            _surface.Draw -= _Draw;
        }
    }
}
