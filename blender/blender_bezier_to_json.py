import bpy

class BezierToJSONOperator(bpy.types.Operator):
    """Tooltip"""
    bl_idname = "curve.bezier_to_json_operator"
    bl_label = "Bezier to JSON Export"

    @classmethod
    def poll(cls, context):
        # Ensure that we have only one curve selected :
        return  bpy.context.mode == 'OBJECT' and len(bpy.context.selected_objects) == 1 and bpy.context.selected_objects[0].type == 'CURVE'

    def execute(self, context):
        curve = bpy.context.selected_objects[0].data.splines[0]
        for anchor in curve.bezier_points:
            print("{{\"anchor\":[{x},{y},{z}]}}".format(x=anchor.co.x, y=anchor.co.y, z=anchor.co.z))
        return {'FINISHED'}


def register():
    bpy.utils.register_class(BezierToJSONOperator)


def unregister():
    bpy.utils.unregister_class(BezierToJSONOperator)


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.curve.bezier_to_json_operator()
