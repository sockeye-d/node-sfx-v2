using Godot;
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
        public GraphNode Source;

        /// <summary>
        /// Override this to provide functionality to the node
        /// </summary>
        /// <param name="args">The arguments passed in either by the user or by the node connected</param>
        /// <returns></returns>
        protected abstract double Calculate(double[] args);

        protected virtual void _UpdateNodeArguments()
        {
            return;
        }

        protected static double _Remap(double x, double fromMin, double fromMax, double toMin, double toMax)
        {
            return (x - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin;
        }

        protected static double _Mix(double a, double b, double fac)
        {
            return a + (b - a) * fac;
        }

        public Node(GraphNode source, string name)
        {
            Source = source;
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

        public void UpdateNodeArguments()
        {
            List<double> args = new();

            foreach (Godot.Node child in Source.GetChildren())
            {
                if (child.Name.ToString().Contains("Input"))
                {
                    args.Add((double)child.Get("slider_value"));
                }
            }

            Arguments = args.ToArray();

            foreach (var node in ConnectedNodes.Values)
            {
                node.UpdateNodeArguments();
            }

            _UpdateNodeArguments();
        }
    }
}
