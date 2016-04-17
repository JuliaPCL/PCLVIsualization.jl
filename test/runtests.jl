using PCLCommon
using PCLIO
using PCLFilters
using PCLVisualization
using Base.Test

table_scene_lms400_path = Pkg.dir("PCLIO", "test", "data",
    "table_scene_lms400.pcd")

@testset "pcl::visualization" begin
    # from statistical outlier remove tutorial
    cloud = PointCloud{PointXYZ}(table_scene_lms400_path)
    cloud_filtered = PointCloud{PointXYZ}()

    sor = StatisticalOutlierRemoval{PointXYZ}()
    setInputCloud(sor, cloud)
    setMeanK(sor, 50)
    setStddevMulThresh(sor, 1.0)
    filter(sor, cloud_filtered)

    viewer = PCLVisualizer("pcl visualizeer", create_interactor=false)
    @assert !hasInteractor(viewer)
    setOffScreenRendering(viewer, true)

    red_handler = PointCloudColorHandlerCustom(cloud, 255, 0, 0)
    green_handler = PointCloudColorHandlerCustom(cloud, 0, 255, 0)
    addPointCloud(viewer, cloud, red_handler, id="cloud")
    addPointCloud(viewer, cloud_filtered, green_handler, id="cloud_filtered")

    data = renderedData(viewer)
    @test data != C_NULL

    # render as png
    dst_filename = string(tempname() |> x -> split(x, '/')[end], ".png")
    PCLVisualization.renderToPng(viewer, dst_filename)
    @test isfile(dst_filename)
    rm(dst_filename)
    @test !isfile(dst_filename)
end
