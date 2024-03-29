using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class OutputNode : Node
    {
        public OutputNode(double[] arguments, string name) : base(arguments, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            return args[0];
        }
    }
}
