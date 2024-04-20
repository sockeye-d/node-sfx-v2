using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class OutputNode : Node
    {
        public OutputNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return args[0];
        }
    }
}
