using Godot;
using SfxNode = NodeSfx.Nodes.Node;
using GdDictionary = Godot.Collections.Dictionary;
using GdArray = Godot.Collections.Array;
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
    private bool _autoRefresh = true;

    private SfxNode _nodeTree = null;

    [Export]
    public AudioStreamPlayer Player;
    [Export]
    public GraphEdit NodeGraph;

    public override void _Ready()
    {
        Player.Play();
        _sampleRate = ((AudioStreamGenerator)Player.Stream).MixRate;
        _audioPlayback = (AudioStreamGeneratorPlayback)Player.GetStreamPlayback();
        NodeGraph.Connect("auto_refresh_changed", new Callable(this, "_OnAutoRefreshChanged"));
        NodeGraph.Connect("connection_changed", new Callable(this, "_RefreshTree"));
    }

    public override void _PhysicsProcess(double delta)
    {
        _FillAudioBuffer();
    }

    private void _FillAudioBuffer()
    {
        int framesAvailable = _audioPlayback.GetFramesAvailable();

        if (_autoRefresh)
        {
            _nodeTree?.UpdateNodeArguments();
        }

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
            "Oscillator" => new OscillatorNode(node, node.Name, (OscillatorNode.OscillatorType)node.GetNode<OptionButton>("TypeSelector").Selected),
            "Oscilloscope" => new OscilloscopeNode(node, node.Name, node.GetNode<Control>("Surface")),
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
