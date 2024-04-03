using Godot;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Reflection;
using System.Text;

namespace NodeSfx.Nodes
{
    public class MathNode : Node
    {
        enum Operation
        {
            ADD,
            MULTIPLY,
            SUBTRACT,
            DIVIDE,
            POWER,
            ABSOLUTE,
            SINE,
            COSINE,
            TANGENT,
            ARCSINE,
            ARCCOSINE,
            ARCTANGENT,
            ARCTANGENT2,
            LOGARITHM,
            SQUARE_ROOT,
            MINIMUM,
            MAXIMUM,
            LESS_THAN,
            GREATER_THAN,
            SIGN,
            ROUND,
            FLOOR,
            CEILING,
            FRACTION,
            MODULO,
        }

        private static readonly Dictionary<Operation, Func<double, double, double>> _funcs = new()
        {
            [Operation.ADD] = (a, b) => a + b,
            [Operation.MULTIPLY] = (a, b) => a * b,
            [Operation.SUBTRACT] = (a, b) => a - b,
            [Operation.DIVIDE] = (a, b) => a / b,
            [Operation.POWER] = (a, b) => Math.Pow(a, b),
            [Operation.ABSOLUTE] = (a, b) => Math.Abs(a),
            [Operation.SINE] = (a, b) => Math.Sin(a),
            [Operation.COSINE] = (a, b) => Math.Cos(a),
            [Operation.TANGENT] = (a, b) => Math.Tan(a),
            [Operation.ARCSINE] = (a, b) => Math.Asin(a),
            [Operation.ARCCOSINE] = (a, b) => Math.Acos(a),
            [Operation.ARCTANGENT] = (a, b) => Math.Atan(a),
            [Operation.ARCTANGENT2] = (a, b) => Math.Atan2(b, a),
            [Operation.LOGARITHM] = (a, b) => Math.Log(a) / Math.Log(b),
            [Operation.SQUARE_ROOT] = (a, b) => Math.Sqrt(a),
            [Operation.MINIMUM] = (a, b) => Math.Min(a, b),
            [Operation.MAXIMUM] = (a, b) => Math.Max(a, b),
            [Operation.LESS_THAN] = (a, b) => a < b? 1.0 : 0.0,
            [Operation.GREATER_THAN] = (a, b) => a > b? 1.0 : 0.0,
            [Operation.SIGN] = (a, b) => Math.Sign(a),
            [Operation.ROUND] = (a, b) => Math.Round(a),
            [Operation.FLOOR] = (a, b) => Math.Floor(a),
            [Operation.CEILING] = (a, b) => Math.Ceiling(a),
            [Operation.FRACTION] = (a, b) => a % 1.0,
            [Operation.MODULO] = (a, b) => a % b,
        };

        private OptionButton _optionButton;
        private Operation _op;
        public MathNode(GraphNode source, string name) : base(source, name)
        {
            _optionButton = source.GetNode<OptionButton>("TypeSelector");
        }

        protected override double Calculate(double[] args)
        {
            return _funcs[_op](args[0], args[1]);
        }

        protected override void _UpdateNodeArguments()
        {
            _op = (Operation)_optionButton.Selected;
        }
    }
}
