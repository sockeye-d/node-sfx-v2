using Godot;
using nodesfxv2.src.extensions;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class CombineNode : Node
    {
        private Vector2.Axis _xChannel = 0;
        private Vector2.Axis _yChannel = 0;
        public CombineNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return new Vector2(args[0].GetAxis(_xChannel), args[1].GetAxis(_yChannel));
        }

        protected override void _UpdateNodeArguments()
        {
            _xChannel = (Vector2.Axis)GetNode<OptionButton>("XChannelSelector").Selected;
            _yChannel = (Vector2.Axis)GetNode<OptionButton>("YChannelSelector").Selected;
        }
    }
}
