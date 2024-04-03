using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class DisplayNode : Node
    {
        private Label _label;
        public DisplayNode(GraphNode source, string name) : base(source, name)
        {
            _label = source.GetNode<Label>("Panel/MarginContainer/Label");
        }

        protected override double Calculate(double[] args)
        {
            _label.Text = args[0].ToString($"F{args[1]}");
            return args[0];
        }
    }
}
