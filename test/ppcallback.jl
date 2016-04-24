using PCLCommon
using PCLIO
using PCLVisualization
using Cxx

global clicked_points = PointCloud{PointXYZ}()
global viewer = PCLVisualizer("point poicking callback test")

function ppcallback(event::cxxt"pcl::visualization::PointPickingEvent&",
        args::Ptr{Void})
    if Int(icxx"$(event).getPointIndex();") == -1
        return
    end

    global viewer
    global clicked_points

    p = PointXYZ()
    icxx"$(event).getPoint($p.x, $p.y, $p.z);"
    push!(clicked_points, p)

    red_handler = PointCloudColorHandlerCustom(clicked_points, 255, 0, 0)
    removePointCloud(viewer, id="clicked_points")
    addPointCloud(viewer, clicked_points, red_handler, id="clicked_points")
    setPointCloudRenderingProperties(viewer, PCL_VISUALIZER_POINT_SIZE, 10,
        id="clicked_points")

    return nothing::Void
end

pcd_file = Pkg.dir("PCLIO", "test", "data", "table_scene_lms400.pcd")
cloud = PointCloud{PointXYZ}(pcd_file);
white_handler = PointCloudColorHandlerCustom(cloud, 255, 255, 255)
addPointCloud(viewer, cloud, white_handler, id="cloud")

registerPointPickingCallback(viewer, ppcallback)

spin(viewer)
close(viewer)
