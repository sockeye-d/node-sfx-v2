using Godot;

namespace NodeSfx.Nodes
{
    public class LoopInputNode : Node
    {
        public string InputName;
        public Vector2 InputValue;

        public LoopInputNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return InputValue;
        }

        protected override void _UpdateNodeArguments()
        {
            InputName = Source.GetNode<LineEdit>("InputNameOutput").Text;
        }
    }
}
