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

        protected override double Calculate(double[] args)
        {
            return Time;
        }
    }
}
