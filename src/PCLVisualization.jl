"""
3D point cloud visualization

http://docs.pointclouds.org/trunk/group__visualization.html

## Exports

$(EXPORTS)
"""
module PCLVisualization

export PointCloudColorHandler, PointCloudColorHandlerRGBField,
    PointCloudColorHandlerCustom,
    PCLVisualizer, setBackgroundColor, addCoordinateSystem, spinOnce,
    setCameraPosition, setCameraClipDistances, initCameraParameters,
    wasStopped, removeAllPointClouds, removeAllShapes, removeShape,
    removeAllCoordinateSystems, resetStoppedFlag, updateCamera, resetCamera,
    spin, setShowFPS, setPointCloudRenderingProperties,
    setShapeRenderingProperties,
    addPointCloud, updatePointCloud, removePointCloud, addText, updateText,
    addCube,
    registerPointPickingCallback,
    getRenderWindow, hasInteractor, setOffScreenRendering, renderedData

using DocStringExtensions
using LibPCL
using PCLCommon
using Cxx

if !LibPCL.has_vtk_backend
    error("Cannot find VTK backend")
end

const libpcl_visualization = LibPCL.find_library_e("libpcl_visualization")
try
    Libdl.dlopen(libpcl_visualization, Libdl.RTLD_GLOBAL)
catch e
    warn("You might need to set DYLD_LIBRARY_PATH to load dependencies proeprty.")
    rethrow(e)
end

cxx"""
#define protected public  // to access PCLVisualizer::interactor_
#include <pcl/visualization/pcl_visualizer.h>
#undef protected
#include <pcl/visualization/common/common.h>
"""

include("const.jl")

abstract PointCloudColorHandler

@defpcltype(PointCloudColorHandlerRGBField{T} <: PointCloudColorHandler,
    "pcl::visualization::PointCloudColorHandlerRGBField")

function (::Type{PointCloudColorHandlerRGBField{T}}){T}(cloud::PointCloud)
    handle = @boostsharedptr(
        "pcl::visualization::PointCloudColorHandlerRGBField<\$T>",
        "\$(cloud.handle)")
    PointCloudColorHandlerRGBField(handle)
end

(::Type{PointCloudColorHandlerRGBField}){T}(cloud::PointCloud{T}) =
    PointCloudColorHandlerRGBField{T}(cloud)

@defpcltype(PointCloudColorHandlerCustom{T} <: PointCloudColorHandler,
    "pcl::visualization::PointCloudColorHandlerCustom")

function (::Type{PointCloudColorHandlerCustom{T}}){T}(cloud::PointCloud,
    r, g, b)
    handle = @boostsharedptr(
        "pcl::visualization::PointCloudColorHandlerCustom<\$T>",
        "\$(cloud.handle), \$r, \$g, \$b")
    PointCloudColorHandlerCustom(handle)
end

(::Type{PointCloudColorHandlerCustom}){T}(cloud::PointCloud{T}, r, g, b) =
    PointCloudColorHandlerCustom{T}(cloud, r, g, b)

const CxxPCLVisualizerPtr =
    cxxt"boost::shared_ptr<pcl::visualization::PCLVisualizer>"

type PCLVisualizer
    handle::CxxPCLVisualizerPtr
    PCLVisualizer(handle::CxxPCLVisualizerPtr) = new(handle)
end

function PCLVisualizer(name::AbstractString=""; create_interactor::Bool=true)
    handle = @boostsharedptr("pcl::visualization::PCLVisualizer",
        "\$(pointer(name)), \$create_interactor")
    PCLVisualizer(handle)
end
PCLCommon.use_count(viewer::PCLVisualizer) = use_count(viewer.handle)
Base.pointer(viewer::PCLVisualizer) = pointer(viewer.handle)
function Base.convert(::Type{PCLVisualizer},
        p::pcpp"pcl::visualization::PCLVisualizer")
    sp = icxx"return boost::shared_ptr<pcl::visualization::PCLVisualizer>($p);"
    PCLVisualizer(sp)
end
Base.convert(::Type{PCLVisualizer}, p::Ptr{Void}) =
    convert(PCLVisualizer, pcpp"pcl::visualization::PCLVisualizer"(p))

setBackgroundColor(viewer::PCLVisualizer, x, y, z) =
    icxx"$(viewer.handle)->setBackgroundColor($x, $y, $z);"
addCoordinateSystem(viewer::PCLVisualizer, scale) =
    icxx"$(viewer.handle)->addCoordinateSystem($scale);"
addCoordinateSystem(viewer::PCLVisualizer, scale, x, y, z) =
    icxx"$(viewer.handle)->addCoordinateSystem($scale, $x, $y, $z);"
spinOnce(viewer::PCLVisualizer, spin=1) =
    icxx"$(viewer.handle)->spinOnce($spin);"

# Generally, you don't have to chagne camera parameters manually. This would be
# useful for off-screen rendering in paricular.
function setCameraPosition(viewer::PCLVisualizer,
        pos_x, pos_y, pos_z,
        up_x, up_y, up_z; viewport::Integer=0)
    icxx"$(viewer.handle)->setCameraPosition(
        $pos_x, $pos_y, $pos_z, $up_x, $up_y, $up_z, $viewport);"
end
function setCameraPosition(viewer::PCLVisualizer,
        pos_x, pos_y, pos_z,
        view_x, view_y, view_z,
        up_x, up_y, up_z; viewport::Integer=0)
    icxx"$(viewer.handle)->setCameraPosition(
        $pos_x, $pos_y, $pos_z, $view_x, $view_y, $view_z,
        $up_x, $up_y, $up_z, $viewport);"
end
function setCameraClipDistances(viewer::PCLVisualizer, near, far;
    viewport::Integer=0)
    icxx"$(viewer.handle)->setCameraClipDistances($near, $far, $viewport);"
end

import Base: close

for f in [
        :initCameraParameters,
        :wasStopped,
        :removeAllPointClouds,
        :removeAllShapes,
        :removeAllCoordinateSystems,
        :resetStoppedFlag,
        :close,
        :updateCamera,
        :resetCamera,
        :spin,
        ]
    body = Expr(:macrocall, Symbol("@icxx_str"), "\$(viewer.handle)->$f();")
    @eval $f(viewer::PCLVisualizer) = $body
end
setShowFPS(viewer::PCLVisualizer, v::Bool) =
    icxx"$(viewer.handle)->setShowFPS($v);"
function setPointCloudRenderingProperties(viewer::PCLVisualizer, property,
        value; id::AbstractString="cloud", viewport::Int=0)
    icxx"$(viewer.handle)->setPointCloudRenderingProperties(
            $property, $value, $(pointer(id)), $viewport);"
end
function setPointCloudRenderingProperties(viewer::PCLVisualizer, property,
        val1, val2, val3; id::AbstractString="cloud", viewport::Int=0)
    icxx"$(viewer.handle)->setPointCloudRenderingProperties(
            $property, $val1, $val2, $val3, $(pointer(id)), $viewport);"
end
function setShapeRenderingProperties(viewer::PCLVisualizer, property, value,
    id::AbstractString; viewport=0)
    icxx"$(viewer.handle)->setShapeRenderingProperties(
            $property, $value, $(pointer(id)), $viewport);"
end
function setShapeRenderingProperties(viewer::PCLVisualizer, property,
        val1, val2, val3, id::AbstractString; viewport::Int=0)
    icxx"$(viewer.handle)->setShapeRenderingProperties(
            $property, $val1, $val2, $val3, $(pointer(id)), $viewport);"
end

function removeShape(viewer::PCLVisualizer, name::AbstractString)
    icxx"$(viewer.handle)->removeShape($(pointer(name)));"
end

function addPointCloud{T}(viewer::PCLVisualizer, cloud::PointCloud{T};
    id::AbstractString="cloud", viewport::Int=0)
    icxx"$(viewer.handle)->addPointCloud($(cloud.handle), $(pointer(id)),
        $viewport);"
end

function addPointCloud{T}(viewer::PCLVisualizer, cloud::PointCloud{T},
    color_handler::PointCloudColorHandler;
    id::AbstractString="cloud", viewport::Int=0)
    icxx"$(viewer.handle)->addPointCloud($(cloud.handle),
        *$(handle(color_handler)), $(pointer(id)), $viewport);"
end

function updatePointCloud{T}(viewer::PCLVisualizer, cloud::PointCloud{T};
    id::AbstractString="cloud")
    icxx"$(viewer.handle)->updatePointCloud($(cloud.handle),
        $(pointer(id)));"
end

function updatePointCloud{T}(viewer::PCLVisualizer, cloud::PointCloud{T},
    color_handler::PointCloudColorHandler; id::AbstractString="cloud")
    icxx"$(viewer.handle)->updatePointCloud($(cloud.handle),
        *$(handle(color_handler)), $(pointer(id)));"
end

function removePointCloud(viewer::PCLVisualizer;
        id::AbstractString="cloud", viewport::Int=0)
    icxx"$(viewer.handle)->removePointCloud($(pointer(id)), $viewport);"
end

function addText(viewer::PCLVisualizer, text::AbstractString, xpos, ypos;
        id::AbstractString="", viewport::Int=0)
    icxx"$(viewer.handle)->addText($(pointer(text)), $xpos, $ypos,
        $(pointer(id)), $viewport);"
end

function addText(viewer::PCLVisualizer, text::AbstractString, xpos, ypos,
        r, g, b; id::AbstractString="", viewport::Int=0)
    icxx"$(viewer.handle)->addText($(pointer(text)), $xpos, $ypos,
        $r, $g, $b, $(pointer(id)), $viewport);"
end

function updateText(viewer::PCLVisualizer, text::AbstractString, xpos, ypos;
        id::AbstractString="")
    icxx"$(viewer.handle)->updateText($(pointer(text)), $xpos, $ypos,
        $(pointer(id)));"
end

function updateText(viewer::PCLVisualizer, text::AbstractString, xpos, ypos,
        r, g, b; id::AbstractString="")
    icxx"$(viewer.handle)->updateText($(pointer(text)), $xpos, $ypos,
        $r, $g, $b, $(pointer(id)));"
end

function addCube(viewer::PCLVisualizer, coeffs, name::AbstractString)
    icxx"$(viewer.handle)->addCube($coeffs, $(pointer(name)));"
end
function addCube(viewer::PCLVisualizer, x_min, x_max, y_min, y_max, z_min, z_max;
    r=1.0, g=1.0, b=1.0, id::AbstractString="cube", viewport=0)
    icxx"""
    $(viewer.handle)->addCube($x_min, $x_max, $y_min, $y_max, $z_min, $z_max,
        $r, $g, $b, $(pointer(id)), $(viewport));
    """
end

function run(viewer::PCLVisualizer; spin::Int=1, sleep::Int=100000)
    icxx"""
    while (!$(viewer.handle)->wasStopped()) {
        $(viewer.handle)->spinOnce($spin);
        boost::this_thread::sleep(boost::posix_time::microseconds($sleep));
    }
    """
end

# callback must be a valid c function pointer
function registerPointPickingCallback(viewer::PCLVisualizer, callback::Ptr{Void},
        args=C_NULL)
    @assert callback != C_NULL
    icxx"""
        $(viewer.handle)->registerPointPickingCallback(
            (void(*)(const pcl::visualization::PointPickingEvent&,void*))$(callback),
            (void*)$args);
    """
end

function registerPointPickingCallback(viewer::PCLVisualizer, callback::Function,
        args=C_NULL)
    ccallback = cfunction(callback, Void,
        (cxxt"const pcl::visualization::PointPickingEvent&", Ptr{Void}))
    registerPointPickingCallback(viewer, ccallback, args)
end

### For off-screen rendering ###

cxx"""
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkRenderWindow.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkSmartPointer.h>
#include <vtkWindowToImageFilter.h>
#include <vtkPNGWriter.h>
"""

cxx"""
namespace vis {

int renderToPng(vtkSmartPointer<vtkRenderWindow> &renderWindow,
                const char *filename) {
  renderWindow->Render();

  vtkSmartPointer<vtkWindowToImageFilter> windowToImageFilter =
      vtkSmartPointer<vtkWindowToImageFilter>::New();
  windowToImageFilter->SetInput(renderWindow);
  windowToImageFilter->Update();

  vtkSmartPointer<vtkPNGWriter> writer = vtkSmartPointer<vtkPNGWriter>::New();
  writer->SetFileName(filename);
  writer->SetInputConnection(windowToImageFilter->GetOutputPort());
  writer->Write();
  return 0;
}

} // end namespace vis
"""

getRenderWindow(viewer::PCLVisualizer) =
    icxx"$(viewer.handle)->getRenderWindow();"
# NOTE: I had to access a protected  member of PCLVisualizer  `interactor_`
hasInteractor(viewer::PCLVisualizer) =
    icxx"$(viewer.handle)->interactor_ != NULL;"

function setOffScreenRendering(viewer::PCLVisualizer, v::Bool)
    if hasInteractor(viewer) && v
        error("Shouldn't have interactor for off screeen rendering")
    end
    icxx"$(getRenderWindow(viewer))->SetOffScreenRendering($v);"
end

renderToPng(viewer::PCLVisualizer, s::AbstractString) =
    @cxx vis::renderToPng(getRenderWindow(viewer), pointer(s))


cxx"""
namespace vis {

std::vector<unsigned char>
renderToVec(vtkSmartPointer<vtkRenderWindow> &renderWindow) {
  renderWindow->Render();

  vtkSmartPointer<vtkWindowToImageFilter> windowToImageFilter =
      vtkSmartPointer<vtkWindowToImageFilter>::New();
  windowToImageFilter->SetInput(renderWindow);
  windowToImageFilter->Update();

  vtkSmartPointer<vtkPNGWriter> writer = vtkSmartPointer<vtkPNGWriter>::New();
  writer->SetWriteToMemory(1);
  writer->SetInputConnection(windowToImageFilter->GetOutputPort());
  writer->Write();

  auto rawPngBuffer = writer->GetResult();
  auto rawPointer = rawPngBuffer->GetPointer(0);
  auto total_size =
      rawPngBuffer->GetDataSize() * rawPngBuffer->GetDataTypeSize();
  std::vector<unsigned char> buffer(rawPointer, rawPointer + total_size);

  return buffer;
}

} // end namespace vis
"""

# > v = renderedData(viewer)
# > display("text/html", "<img src=data:image/png;base64,$(base64encode(v))>")
# should display image in a jupyter notebook
function renderedData(viewer::PCLVisualizer)
    vec = @cxx vis::renderToVec(getRenderWindow(viewer))
    p = icxx"&$(vec[0]);"
    pointer_to_array(p, length(vec))
end

# just for debugging: to be removed
cxx"""
namespace vis {

void dumpCameraParameters(pcl::visualization::PCLVisualizer::Ptr &vis) {
  std::vector<pcl::visualization::Camera> cameras;
  vis->getCameras(cameras);
  for (size_t i = 0; i < cameras.size(); ++i) {
    auto &c = cameras[i];
    std::cout << "[Camera #" << i << "]" << std::endl;
    std::cout << "focal : " << c.focal[0] << " " << c.focal[1] << " "
              << c.focal[2] << std::endl;
    std::cout << "pos : " << c.pos[0] << " " << c.pos[1] << " " << c.pos[2]
              << std::endl;
    std::cout << "view : " << c.view[0] << " " << c.view[1] << " " << c.view[2]
              << std::endl;
    std::cout << "clip : " << c.clip[0] << " " << c.clip[1] << std::endl;
    std::cout << "fovy : " << c.fovy << std::endl;
    std::cout << "window_size : " << c.window_size[0] << " " << c.window_size[1]
              << std::endl;
    std::cout << "window_pos : " << c.window_pos[0] << " " << c.window_pos[1]
              << std::endl;
  }
}

} // end namespace vis
"""
dumpCameraParameters(viewer::PCLVisualizer) =
    @cxx vis::dumpCameraParameters(viewer)


end # module
