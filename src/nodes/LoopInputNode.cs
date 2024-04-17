using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class LoopInputNode : Node
    {
        public string InputName;
        public double InputValue;

        public LoopInputNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            return InputValue;
        }

        protected override void _UpdateNodeArguments()
        {
            InputName = Source.GetNode<LineEdit>("InputNameOutput").Text;
        }
    }
}
