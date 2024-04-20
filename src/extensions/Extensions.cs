using Godot;
using System;
using System.Runtime.CompilerServices;

namespace nodesfxv2.src.extensions
{
    public static class Extensions
    {
        public static Vector2 AsVector2(this Variant value)
        {
            switch (value.VariantType)
            {
                case Variant.Type.Float:
                    {
                        float valueAsFloat = (float)value.AsDouble();

                        return new Vector2(valueAsFloat, valueAsFloat);
                    }

                default:
                    throw new InvalidCastException();
            }
        }

        public static float GetAxis(this Vector2 value, Vector2.Axis axis)
        {
            return value[(int)axis];
        }

        public static Vector2 AsVector2(this float value)
        {
            return new Vector2(value, value);
        }
    }
}
