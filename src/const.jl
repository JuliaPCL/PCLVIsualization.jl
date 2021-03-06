for name in [
    :PCL_INSIDE_FRUSTUM,
    :PCL_INTERSECT_FRUSTUM,
    :PCL_OUTSIDE_FRUSTUM,

    :PCL_VISUALIZER_POINT_SIZE,
    :PCL_VISUALIZER_OPACITY,
    :PCL_VISUALIZER_LINE_WIDTH,
    :PCL_VISUALIZER_FONT_SIZE,
    :PCL_VISUALIZER_COLOR,
    :PCL_VISUALIZER_REPRESENTATION,
    :PCL_VISUALIZER_IMMEDIATE_RENDERING,
    :PCL_VISUALIZER_SHADING,
    :PCL_VISUALIZER_LUT,

    :PCL_VISUALIZER_REPRESENTATION_POINTS,
    :PCL_VISUALIZER_REPRESENTATION_WIREFRAME,
    :PCL_VISUALIZER_REPRESENTATION_SURFACE,

    :PCL_VISUALIZER_SHADING_FLAT,
    :PCL_VISUALIZER_SHADING_GOURAUD,
    :PCL_VISUALIZER_SHADING_PHONG,

    :PCL_VISUALIZER_LUT_JET,
    :PCL_VISUALIZER_LUT_JET_INVERSE,
    :PCL_VISUALIZER_LUT_HSV,
    :PCL_VISUALIZER_LUT_HSV_INVERSE,
    :PCL_VISUALIZER_LUT_GREY,
    ]
    ex = Expr(:macrocall, Symbol("@icxx_str"), string("pcl::visualization::", name, ";"))
    cppname = string("pcl::visualization::", name)
    @eval begin
        @doc """
        $($cppname)
        """ global const $name = $ex
        @assert isa($name, Cxx.CppEnum)
        export $name
    end
end
