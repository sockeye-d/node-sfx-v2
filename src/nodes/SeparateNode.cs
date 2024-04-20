using Godot;
using nodesfxv2.src.extensions;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class SeparateNode : Node
    {
        private Vector2.Axis _channel = 0;
        public SeparateNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return args[0].GetAxis(_channel).AsVector2();
        }

        protected override void _UpdateNodeArguments()
        {
            _channel = (Vector2.Axis)GetNode<OptionButton>("ChannelSelector").Selected;
        }
    }
}
