using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace NodeSfx.Nodes
{
    public class LoopNode : Node
    {
        private readonly Dictionary<string, double> _inputs = new();
        private readonly Dictionary<string, double> _defaultInputs = new();
        private readonly Dictionary<int, string> _inputNames = new();
        private int _loopIterations = 0;
        public LoopNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override double Calculate(double[] args)
        {
            _ResetInputs();
            for (int i = 0; i < _loopIterations; i++)
            {
                _SetInputNodes(this, _inputs);
                _ExecuteInputNodes();
            }
            return args[0];
        }

        protected override void _UpdateNodeArguments()
        {
            int nonInputChildren = 0;
            foreach (Godot.Node node in Source.GetChildren())
            {
                // node (VBoxContainer)
                //  - HBoxContainer
                //     - InputName
                //  - DefaultValueInput
                if (node.HasMeta("is_input"))
                {
                    LineEdit lineEdit = node.GetNode<LineEdit>("HBoxContainer/InputName");
                    _inputNames[node.GetIndex() - nonInputChildren] = lineEdit.Text;
                    _defaultInputs[lineEdit.Text] = node.GetNode("DefaultValueInput").Get("slider_value").AsDouble();
                }
                else
                {
                    nonInputChildren++;
                }
            }

            _loopIterations = Source.GetNode("LoopIterations").Get("slider_value").AsInt32();
        }

        private void _ResetInputs()
        {
            foreach (var key in _inputs.Keys)
            {
                _inputs[key] = _defaultInputs[key];
            }
        }

        private void _ExecuteInputNodes()
        {
            if (ConnectedNodes.Count == 0)
            {
                return;
            }

            for (int i = 0; i < _inputNames.Count; i++)
            {
                if (ConnectedNodes.ContainsKey(i + 1))
                {
                    // Adds one to index because the loop output connection isn't an input
                    //                                       |||||
                    //                                       vvvvv
                    _inputs[_inputNames[i]] = ConnectedNodes[i + 1].Execute();
                }
                // If there isn't a node connected to it, there's no need to do
                // anything because it has already been set to the default value
            }
        }

        private static string _DictToString<TKey, TValue>(Dictionary<TKey, TValue> dict)
        {
            StringBuilder sb = new("{");
            for (int i = 0; i < dict.Count; i++)
            {
                sb.Append($"{dict.Keys.ToArray()[i]} = {dict[dict.Keys.ToArray()[i]]}{(i == dict.Count - 1 ? "" : ",")}");
            }
            sb.Append('}');
            return sb.ToString();
        }

        /// <summary>
        /// Propogates the inputs to all the connected LoopInput nodes
        /// </summary>
        /// <param name="parent">The node to start at. Normally a reference to the self></param>
        /// <param name="inputs">The inputs to pass along</param>
        private static void _SetInputNodes(Node parent, Dictionary<string, double> inputs)
        {
            foreach (var node in parent.ConnectedNodes.Values)
            {
                if (node is LoopInputNode loopInputNode)
                {
                    if (inputs.ContainsKey(loopInputNode.InputName))
                    {
                        loopInputNode.InputValue = inputs[loopInputNode.InputName];
                    }
                }
                else
                {
                    _SetInputNodes(node, inputs);
                }
            }
        }
    }
}
