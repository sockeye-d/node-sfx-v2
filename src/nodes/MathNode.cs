using Godot;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
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

        private static readonly ReadOnlyDictionary<Operation, Func<float, float, float>> _funcs = new(new Dictionary<Operation, Func<float, float, float>>
        {
            [Operation.ADD] = (a, b) => a + b,
            [Operation.MULTIPLY] = (a, b) => a * b,
            [Operation.SUBTRACT] = (a, b) => a - b,
            [Operation.DIVIDE] = (a, b) => a / b,
            [Operation.POWER] = (a, b) => MathF.Pow(a, b),
            [Operation.ABSOLUTE] = (a, b) => MathF.Abs(a),
            [Operation.SINE] = (a, b) => MathF.Sin(a),
            [Operation.COSINE] = (a, b) => MathF.Cos(a),
            [Operation.TANGENT] = (a, b) => MathF.Tan(a),
            [Operation.ARCSINE] = (a, b) => MathF.Asin(a),
            [Operation.ARCCOSINE] = (a, b) => MathF.Acos(a),
            [Operation.ARCTANGENT] = (a, b) => MathF.Atan(a),
            [Operation.ARCTANGENT2] = (a, b) => MathF.Atan2(b, a),
            [Operation.LOGARITHM] = (a, b) => MathF.Log(a) / MathF.Log(b),
            [Operation.SQUARE_ROOT] = (a, b) => MathF.Sqrt(a),
            [Operation.MINIMUM] = (a, b) => MathF.Min(a, b),
            [Operation.MAXIMUM] = (a, b) => MathF.Max(a, b),
            [Operation.LESS_THAN] = (a, b) => a < b? 1.0f : 0.0f,
            [Operation.GREATER_THAN] = (a, b) => a > b? 1.0f : 0.0f,
            [Operation.SIGN] = (a, b) => MathF.Sign(a),
            [Operation.ROUND] = (a, b) => MathF.Round(a),
            [Operation.FLOOR] = (a, b) => MathF.Floor(a),
            [Operation.CEILING] = (a, b) => MathF.Ceiling(a),
            [Operation.FRACTION] = (a, b) => a % 1.0f,
            [Operation.MODULO] = (a, b) => a % b,
        });

        private OptionButton _optionButton;
        private Operation _op;
        public MathNode(GraphNode source, string name) : base(source, name)
        {
            _optionButton = source.GetNode<OptionButton>("TypeSelector");
        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            float x = _funcs[_op](args[0].X, args[1].X);
            float y = _funcs[_op](args[0].Y, args[1].Y);
            return new Vector2(x, y);
        }

        protected override void _UpdateNodeArguments()
        {
            _op = (Operation)_optionButton.Selected;
        }
    }
}
