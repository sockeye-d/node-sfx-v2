using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class TimeNode : Node
    {
        public TimeNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return new Vector2((float)Time, (float)Time);
        }
    }
}
