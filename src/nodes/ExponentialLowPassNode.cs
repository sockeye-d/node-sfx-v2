using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class ExponentialLowPassNode : Node
    {
        private double _value;
        public ExponentialLowPassNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            _value += (args[0] - _value) * (1.0 - Math.Pow(args[1], 0.01));
            return _Mix(args[0], _value, args[2]);
        }
        
        private static double _ExpDamp(double source, double target, double smoothing, double dt)
        {
            return _Mix(target, source, Math.Pow(smoothing, dt));
        }
    }
}
