using Godot;
using SfxNode = NodeSfx.Nodes.Node;
using System;
using NodeSfx.Nodes;
using System.Collections.Generic;

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
    private bool _autoRefresh;

    private SfxNode _nodeTree = null;

    [Export]
    public AudioStreamPlayer Player;
    [Export]
    public GraphEdit NodeGraph;
    [Export]
    public int MinAudioFramesPushed = 4410;

    public override void _Ready()
    {
        Player.Play();
        _sampleRate = ((AudioStreamGenerator)Player.Stream).MixRate;
        _audioPlayback = (AudioStreamGeneratorPlayback)Player.GetStreamPlayback();
        NodeGraph.Connect("auto_refresh_changed", new Callable(this, "_OnAutoRefreshChanged"));
        NodeGraph.Connect("refresh", new Callable(this, "_RefreshTree"));
    }

    public override void _Process(double delta)
    {
        if (Input.IsActionJustPressed("refresh"))
        {
            _nodeTree = _ConstructNodeTree(_ConvertGodotConnections(NodeGraph.GetConnectionList()), "OutputNode");
        }
        _FillAudioBuffer();
    }

    private void _FillAudioBuffer()
    {
        int framesAvailable = _audioPlayback.GetFramesAvailable();

        if (framesAvailable < MinAudioFramesPushed)
        {
            return;
        }

        if (_autoRefresh)
        {
            _RefreshTree();
            GD.Print("refreshed tree");
        }

        double invSampleRate = 1.0 / _sampleRate;
        SfxNode.SampleRate = _sampleRate;

        for (int i = 0; i < framesAvailable; i++)
        {
            SfxNode.Time = _time;
            double val = _nodeTree == null ? 0.0 : _nodeTree.Execute();
            _audioPlayback.PushFrame(new Vector2((float)val, (float)val));
            _time += invSampleRate;
        }
    }

    private Connection[] _ConvertGodotConnections(Godot.Collections.Array<Godot.Collections.Dictionary> connections)
    {
        Connection[] newConnections = new Connection[connections.Count];
        for (int i = 0; i < connections.Count; i++)
        {
            newConnections[i] = new Connection(connections[i]);
        }

        return newConnections;
    }

    private double[] _GetNodeArguments(GraphNode node)
    {
        List<double> args = new();

        foreach (Godot.Node child in node.GetChildren())
        {
            if (child.Name.ToString().Contains("Input"))
            {
                args.Add((double)child.Get("slider_value"));
            }
        }

        return args.ToArray();
    }

    private SfxNode _GetSfxNodeFromGraphNode(GraphNode node)
    {
        string type = node.Get("type").AsString();
        return type switch
        {
            "Output" => new OutputNode(_GetNodeArguments(node), node.Name),
            "Oscillator" => new OscillatorNode(_GetNodeArguments(node), node.Name, (OscillatorNode.OscillatorType)node.GetNode<OptionButton>("TypeSelector").Selected),
            "Oscilloscope" => new OscilloscopeNode(_GetNodeArguments(node), node.Name, node.GetNode<Control>("Surface")),
            _ => null,
        }; ;
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

    private void _OnAutoRefreshChanged(bool state)
    {
        _autoRefresh = state;
    }

    private void _RefreshTree()
    {
        _nodeTree?.Dispose();
        _nodeTree = _ConstructNodeTree(_ConvertGodotConnections(NodeGraph.GetConnectionList()), "OutputNode");
    }
}
