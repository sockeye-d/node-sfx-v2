using Godot;
using System;
using System.Collections.Generic;

namespace NodeSfx.Nodes
{
    public class AudioFileNode : Node
    {
        private string _path = "";
        public AudioFileNode(GraphNode source, string name) : base(source, name)
        {

        }

        protected override Vector2 Calculate(Vector2[] args)
        {
            return args[0];
        }

        protected override void _UpdateNodeArguments()
        {
            FileAccess.FileExists(_path);
        }

        private float[] _ImportAudioFile(string path)
        {
            Godot.ResourceLoader.Load(_path);
            return [];
        }
    }
}
