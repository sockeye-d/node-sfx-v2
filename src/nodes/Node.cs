using Godot;
using System;
using System.Collections.Generic;
using System.Text;
using Vector2 = Godot.Vector2;

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

        public Vector2[] Arguments;

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
        protected abstract Vector2 Calculate(Vector2[] args);

        protected virtual void _UpdateNodeArguments()
        {
            return;
        }

        protected static Vector2 _Remap(Vector2 x, Vector2 fromMin, Vector2 fromMax, Vector2 toMin, Vector2 toMax)
        {
            return (x - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin;
        }

        protected static float _Remap(float x, float fromMin, float fromMax, float toMin, float toMax)
        {
            return (x - fromMin) / (fromMax - fromMin) * (toMax - toMin) + toMin;
        }

        protected static Vector2 _Mix(Vector2 a, Vector2 b, Vector2 fac)
        {
            return a + (b - a) * fac;
        }

        protected static double _Mix(double a, double b, double fac)
        {
            return a + (b - a) * fac;
        }

        protected static float _Mix(float a, float b, float fac)
        {
            return a + (b - a) * fac;
        }

        public Node(GraphNode source, string name)
        {
            Source = source;
            Name = name;
            ConnectedNodes = new();
        }

        public void Connect(int port, Node node)
        {
            ConnectedNodes.Add(port, node);
        }

        public Vector2 Execute()
        {
            Vector2[] computedArgs = new Vector2[Arguments.Length];
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
            List<Vector2> args = new();

            foreach (Godot.Node child in Source.GetChildren())
            {
                if (child.HasMeta("is_slider_combo"))
                {
                    float arg = (float)child.Get("slider_value");
                    args.Add(new Vector2(arg, arg));
                }
            }

            Arguments = args.ToArray();

            foreach (var node in ConnectedNodes.Values)
            {
                node.UpdateNodeArguments();
            }

            _UpdateNodeArguments();
        }

        public T GetNode<T>(string path) where T : Godot.Node
        {
            return Source.GetNode<T>(path);
        }
    }
}
