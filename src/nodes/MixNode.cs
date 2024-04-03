using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class MixNode : Node
    {
        public MixNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            return _Mix(args[1], args[2], args[0]);
        }
    }
}
