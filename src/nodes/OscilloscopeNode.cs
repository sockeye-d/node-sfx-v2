using Godot;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Channels;

namespace NodeSfx.Nodes
{
    public class OscilloscopeNode : Node
    {
        enum ChannelMode
        {
            CHANNEL_0,
            CHANNEL_1,
            AVERAGE,
            MINIMUM,
            MAXIMUM,
            COMBINED,
        }

        private Control _surface;
        private int _queueLength;
        private float _scale;
        private float _offset;
        private Queue<Vector2> _queue;

        private ChannelMode _channelMode;
        private Func<Vector2, float> _channelOp;

        private ReadOnlyDictionary<ChannelMode, Func<Vector2, float>> _modeMap = new(new Dictionary<ChannelMode, Func<Vector2, float>>()
        {
            [ChannelMode.CHANNEL_0] = (vec) => vec.X,
            [ChannelMode.CHANNEL_1] = (vec) => vec.Y,
            [ChannelMode.AVERAGE] = (vec) => (vec.X + vec.Y) * 0.5f,
            [ChannelMode.MINIMUM] = (vec) => MathF.Min(vec.X, vec.Y),
            [ChannelMode.MAXIMUM] = (vec) => MathF.Max(vec.X, vec.Y),
        });

        public OscilloscopeNode(GraphNode source, string name) : base(source, name)
        {
            _surface = source.GetNode<Control>("Surface");
            _surface.Draw += _Draw;
            _queue = new Queue<Vector2>();
        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            _queueLength = (int)args[1].X;
            _offset = args[2].X;
            _scale = args[3].X;

            _queue.Enqueue(args[0]);

            while (_queue.Count > _queueLength)
            {
                _queue.Dequeue();
            }

            return args[0];
        }

        protected override void _UpdateNodeArguments()
        {
            _channelMode = (ChannelMode)Source.GetNode<OptionButton>("ChannelSelector").Selected;

            _channelOp = _modeMap.GetValueOrDefault(_channelMode, null);
        }

        private void _Draw()
        {
            if (_queue.Count > 1)
            {
                int i = 0;
                if (_channelMode == ChannelMode.COMBINED)
                {
                    Vector2[] ch0Points = new Vector2[_queue.Count];
                    Vector2[] ch1Points = new Vector2[_queue.Count];
                    foreach (Vector2 vecValue in _queue)
                    {
                        float x = i / (_queue.Count - 1.0f);
                        float xy = Math.Clamp(vecValue.X * _scale + _offset, 0.0f, 1.0f);
                        float yy = Math.Clamp(vecValue.Y * _scale + _offset, 0.0f, 1.0f);
                        ch0Points[i] = new Vector2(x, 1.0f - xy) * _surface.GetRect().Abs().Size;
                        ch1Points[i] = new Vector2(x, 1.0f - yy) * _surface.GetRect().Abs().Size;
                        i++;
                    }
                    _surface.DrawPolyline(ch0Points, new Color(0.2f, 1.0f, 0.3f));
                    _surface.DrawPolyline(ch1Points, new Color(0.8f, 0.0f, 0.7f));
                }
                else
                {
                    Vector2[] points = new Vector2[_queue.Count];
                    foreach (Vector2 vecValue in _queue)
                    {
                        float value = _channelOp(vecValue);

                        float x = i / (_queue.Count - 1.0f);
                        float y = value * _scale + _offset;
                        y = Math.Clamp(y, 0.0f, 1.0f);
                        points[i] = new Vector2(x, 1.0f - y) * _surface.GetRect().Abs().Size;
                        i++;
                    }
                    _surface.DrawPolyline(points, new Color(0.2f, 1.0f, 0.3f));
                }
            }
        }

        public override void Dispose()
        {
            base.Dispose();
            _surface.Draw -= _Draw;
        }
    }
}
