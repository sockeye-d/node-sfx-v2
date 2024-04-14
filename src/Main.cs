using Godot;
using SfxNode = NodeSfx.Nodes.Node;
using GdDictionary = Godot.Collections.Dictionary;
using NodeSfx.Nodes;
using System;

public partial class Main : Control
{
    private class Connection
    {
        public StringName FromNode;
        public int FromPort;
        public StringName ToNode;
        public int ToPort;

        public Connection(StringName fromNode, int fromPort, StringName toNode, int toPort)
        {
            FromNode = fromNode;
            FromPort = fromPort;
            ToNode = toNode;
            ToPort = toPort;
        }

        public Connection(Godot.Collections.Dictionary connection)
        {
            FromNode = (StringName)connection["from_node"];
            FromPort = (int)connection["from_port"];
            ToNode = (StringName)connection["to_node"];
            ToPort = (int)connection["to_port"];
        }

        public override string ToString()
        {
            return $"From port {FromPort} of {FromNode} to port {ToPort} of {ToNode}";
        }
    }

    private AudioStreamGeneratorPlayback _audioPlayback;
    private double _sampleRate;
    private double _time;
    private SfxNode _nodeTree = null;

    [Export]
    public AudioStreamPlayer Player;
    [Export]
    public GraphEdit NodeGraph;

    public override void _Ready()
    {
        NodeGraph.Connect("connection_changed", new Callable(this, "_RefreshTree"));
        NodeGraph.Connect("paused", new Callable(this, "_Pause"));
        NodeGraph.Connect("played", new Callable(this, "_Play"));
        NodeGraph.Connect("rewound", new Callable(this, "_Rewind"));
        NodeGraph.Connect("stopped", new Callable(this, "_Stop"));
        _time = 0;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (Player.Playing && _audioPlayback != null)
        {
            _FillAudioBuffer();
        }
    }

    private void _FillAudioBuffer()
    {
        int framesAvailable = _audioPlayback.GetFramesAvailable();
        _nodeTree?.UpdateNodeArguments();
        double invSampleRate = 1.0 / _sampleRate;
        SfxNode.SampleRate = _sampleRate;

        for (int i = 0; i < framesAvailable; i++)
        {
            SfxNode.Time = _time;
            double val = (_nodeTree?.Execute()).GetValueOrDefault();
            _audioPlayback.PushFrame(new Vector2((float)val, (float)val));
            _time += invSampleRate;
        }
    }

    private Connection[] _ConvertGodotConnections(Godot.Collections.Array<GdDictionary> connections)
    {
        Connection[] newConnections = new Connection[connections.Count];
        for (int i = 0; i < connections.Count; i++)
        {
            newConnections[i] = new Connection(connections[i]);
        }

        return newConnections;
    }

    private SfxNode _GetSfxNodeFromGraphNode(GraphNode node)
    {
        string type = node.Get("type").AsString();
        return type switch
        {
            "Output" => new OutputNode(node, node.Name),
            "Oscillator" => new OscillatorNode(node, node.Name),
            "Oscilloscope" => new OscilloscopeNode(node, node.Name),
            "Time" => new TimeNode(node, node.Name),
            "Automator" => new AutomatorNode(node, node.Name),
            "Display" => new DisplayNode(node, node.Name),
            "Math" => new MathNode(node, node.Name),
            "Exponential low pass" => new ExponentialLowPassNode(node, node.Name),
            "Mix" => new MixNode(node, node.Name),
            "Convolutional low pass" => new ConvolutionalLowPassNode(node, node.Name),
            _ => null,
        };
    }

    private SfxNode _ConstructNodeTree(Connection[] connections, string root)
    {
        GraphNode node = NodeGraph.GetNode<GraphNode>(root);
        SfxNode rootNode = _GetSfxNodeFromGraphNode(node);
        foreach (Connection connection in connections)
        {
            if (connection.ToNode == root)
            {
                rootNode.Connect(connection.ToPort, _ConstructNodeTree(connections, connection.FromNode));
            }
        }

        return rootNode;
    }

    private void _RefreshTree()
    {
        _nodeTree?.Dispose();
        _nodeTree = _ConstructNodeTree(_ConvertGodotConnections(NodeGraph.GetConnectionList()), "OutputNode");
        GD.Print("Refreshed tree");
    }

    private void _Pause()
    {
        Player.Playing = false;
    }

    private void _Play()
    {
        Player.Play();
        _audioPlayback = (AudioStreamGeneratorPlayback)Player.GetStreamPlayback();
        _sampleRate = ((AudioStreamGenerator)Player.Stream).MixRate;
    }

    private void _Stop()
    {
        _Pause();
        _Rewind();
    }

    private void _Rewind()
    {
        _time = 0.0;
    }
}
