using System;
using System.Collections.Generic;
using System.Text;

namespace NodeSfx.Nodes
{
    public abstract class Node : IDisposable
    {
        private static double _sampleRate;
        public static double SampleRate
        {
            get
            {
                return _sampleRate;
            }
            
            set
            {
                _sampleRate = value;
                InvSampleRate = 1.0 / value;
            }
        }

        public static double InvSampleRate { get; private set; }
        public static double Time;

        public double[] Arguments;

        /// <summary>
        /// Maps port numbers to nodes
        /// </summary>
        public Dictionary<int, Node> ConnectedNodes;
        public string Name;

        /// <summary>
        /// Override this to provide functionality to the node
        /// </summary>
        /// <param name="args">The arguments passed in either by the user or by the node connected</param>
        /// <returns></returns>
        protected abstract double Calculate(double[] args);

        public Node(double[] arguments, string name)
        {
            Arguments = arguments;
            Name = name;
            ConnectedNodes = new ();
        }

        public void Connect(int port, Node node)
        {
            ConnectedNodes.Add(port, node);
        }

        public double Execute()
        {
            double[] computedArgs = new double[Arguments.Length];
            for (int i = 0; i < Arguments.Length; i++)
            {
                // If a node is connected, then calculate its value to pass into this node
                // otherwise use the one provided by the numerical input
                computedArgs[i] = ConnectedNodes.ContainsKey(i) ? ConnectedNodes[i].Execute() : Arguments[i];
            }

            return Calculate(computedArgs);
        }

        public override string ToString()
        {
            StringBuilder sb = new();
            foreach (var kvp in ConnectedNodes)
            {
                sb.AppendLine($"{Name} is connnected to {kvp.Value.Name} on port {kvp.Key}");
                string previousNodeString = kvp.Value.ToString();

                foreach (string line in previousNodeString.Split('\n'))
                {
                    if (!string.IsNullOrEmpty(line))
                    {
                        sb.AppendLine($"\t{line}");
                    }
                }
            }
            return $"{sb}";
        }

        public virtual void Dispose()
        {
            foreach (var node in ConnectedNodes.Values)
            {
                node.Dispose();
            }
        }
    }
}
