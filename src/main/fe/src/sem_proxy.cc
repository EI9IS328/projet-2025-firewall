//************************************************************************
//   proxy application v.0.0.1
//
//  semproxy.cpp: the main interface of  proxy application
//
//************************************************************************

#include "sem_proxy.h"

#include <cartesian_struct_builder.h>
#include <cartesian_unstruct_builder.h>
#include <sem_solver_acoustic.h>
#include <source_and_receiver_utils.h>

#include <cxxopts.hpp>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <variant>
#include <vector>

using namespace SourceAndReceiverUtils;

void SEMproxy::parse_receivers_file(const SemProxyOptions& opt)
{
  std::ifstream ifs(opt.receivers_file);
  if (!ifs)
  {
    throw std::runtime_error("Could not open receivers file: " +
                             opt.receivers_file);
  }

  std::vector<std::array<float, 3>> coords;
  std::string line;
  while (std::getline(ifs, line))
  {
    if (line.empty()) continue;
    for (char& c : line)
      if (c == ',') c = ' ';

    std::istringstream ss(line);
    float x, y, z;
    if (!(ss >> x >> y >> z))
    {
      throw std::runtime_error("Invalid receiver line: '" + line + "'");
    }
    coords.push_back({x, y, z});
  }

  if (coords.empty())
  {
    throw std::runtime_error("No receivers found in file: " +
                             opt.receivers_file);
  }

  nbReceivers = static_cast<int>(coords.size());
  rcvCoords = allocateArray2D<arrayReal>(nbReceivers, 3, "rcvCoords");
  for (int i = 0; i < nbReceivers; ++i)
  {
    rcvCoords(i, 0) = coords[i][0];
    rcvCoords(i, 1) = coords[i][1];
    rcvCoords(i, 2) = coords[i][2];
  }
}

SEMproxy::SEMproxy(const SemProxyOptions& opt)
{
  const int order = opt.order;
  nb_elements_[0] = opt.ex;
  nb_elements_[1] = opt.ey;
  nb_elements_[2] = opt.ez;
  nb_nodes_[0] = opt.ex * order + 1;
  nb_nodes_[1] = opt.ey * order + 1;
  nb_nodes_[2] = opt.ez * order + 1;

  const float spongex = opt.boundaries_size;
  const float spongey = opt.boundaries_size;
  const float spongez = opt.boundaries_size;
  const std::array<float, 3> sponge_size = {spongex, spongey, spongez};
  src_coord_[0] = opt.srcx;
  src_coord_[1] = opt.srcy;
  src_coord_[2] = opt.srcz;

  domain_size_[0] = opt.lx;
  domain_size_[1] = opt.ly;
  domain_size_[2] = opt.lz;
  if (opt.receivers_file == "NONE")
  {
    rcvCoords = allocateArray2D<arrayReal>(1, 3, "rcvCoords");
    rcvCoords(0, 0) = opt.rcvx;
    rcvCoords(0, 1) = opt.rcvy;
    rcvCoords(0, 2) = opt.rcvz;
  }
  else
  {
    parse_receivers_file(opt);
  }

  is_snapshots_ = opt.enableSnapshots;
  snap_time_interval_ = opt.intervalSnapshots;

  is_sismos_ = opt.enableSismos;
  snap_folder_ = opt.folderSnapshots;
  sismos_folder_ = opt.folderSismos;

  bool isModelOnNodes = opt.isModelOnNodes;
  isElastic_ = opt.isElastic;
  cout << boolalpha;
  bool isElastic = isElastic_;

  const SolverFactory::methodType methodType = getMethod(opt.method);
  const SolverFactory::implemType implemType = getImplem(opt.implem);
  const SolverFactory::meshType meshType = getMesh(opt.mesh);
  const SolverFactory::modelLocationType modelLocation =
      isModelOnNodes ? SolverFactory::modelLocationType::OnNodes
                     : SolverFactory::modelLocationType::OnElements;
  const SolverFactory::physicType physicType =
      SolverFactory::physicType::Acoustic;

  float lx = domain_size_[0];
  float ly = domain_size_[1];
  float lz = domain_size_[2];
  int ex = nb_elements_[0];
  int ey = nb_elements_[1];
  int ez = nb_elements_[2];

  if (meshType == SolverFactory::Struct)
  {
    switch (order)
    {
      case 1: {
        model::CartesianStructBuilder<float, int, 1> builder(
            ex, lx, ey, ly, ez, lz, isModelOnNodes);
        m_mesh = builder.getModel();
        break;
      }
      case 2: {
        model::CartesianStructBuilder<float, int, 2> builder(
            ex, lx, ey, ly, ez, lz, isModelOnNodes);
        m_mesh = builder.getModel();
        break;
      }
      case 3: {
        model::CartesianStructBuilder<float, int, 3> builder(
            ex, lx, ey, ly, ez, lz, isModelOnNodes);
        m_mesh = builder.getModel();
        break;
      }
      default:
        throw std::runtime_error(
            "Order other than 1 2 3 is not supported (semproxy)");
    }
  }
  else if (meshType == SolverFactory::Unstruct)
  {
    model::CartesianParams<float, int> param(order, ex, ey, ez, lx, ly, lz,
                                             isModelOnNodes);
    model::CartesianUnstructBuilder<float, int> builder(param);
    m_mesh = builder.getModel();
  }
  else
  {
    throw std::runtime_error("Incorrect mesh type (SEMproxy ctor.)");
  }

  // time parameters
  if (opt.autodt)
  {
    float cfl_factor = (order == 2) ? 0.5 : 0.7;
    dt_ = find_cfl_dt(cfl_factor);
  }
  else
  {
    dt_ = opt.dt;
  }
  timemax_ = opt.timemax;
  num_sample_ = timemax_ / dt_;

  m_solver = SolverFactory::createSolver(methodType, implemType, meshType,
                                         modelLocation, physicType, order);
  m_solver->computeFEInit(*m_mesh, sponge_size, opt.surface_sponge,
                          opt.taper_delta);

  initFiniteElem();

  std::cout << "Number of node is " << m_mesh->getNumberOfNodes() << std::endl;
  std::cout << "Number of element is " << m_mesh->getNumberOfElements()
            << std::endl;
  std::cout << "Launching the Method " << opt.method << ", the implementation "
            << opt.implem << " and the mesh is " << opt.mesh << std::endl;
  std::cout << "Model is on " << (isModelOnNodes ? "nodes" : "elements")
            << std::endl;
  std::cout << "Physics type is " << (isElastic ? "elastic" : "acoustic")
            << std::endl;
  std::cout << "Order of approximation will be " << order << std::endl;
  std::cout << "Time step is " << dt_ << "s" << std::endl;
  std::cout << "Simulated time is " << timemax_ << "s" << std::endl;
  std::cout << "Snapshot enabled: " << is_snapshots_ << std::endl;
  std::cout << "Snapshot interval is " << snap_time_interval_ << std::endl;
  std::cout << "Number of receivers is " << nbReceivers << std::endl;
  std::cout << "Ex=" << ex << " Ey=" << ey << " Ez=" << ez << std::endl;
}

void SEMproxy::generate_snapshot(int indexTimeSample)
{
  std::stringstream filename;
  std::filesystem::path dir = snap_folder_;

  if (!std::filesystem::exists(dir))
  {
    if (!std::filesystem::create_directory(dir))
    {
      std::cout << "Failed to create directory.\n";
    }
  }
  filename << snap_folder_ << "/snapshot_" << std::setfill('0') << std::setw(6)
           << indexTimeSample << ".snapshot";
  int numNodes = m_mesh->getNumberOfNodes();

  std::ofstream outfile(filename.str());
  if (!outfile)
  {
    std::cerr << "Error: Could not open file " << filename.str() << std::endl;
    return;
  }

  outfile << "x y z pressure\n";

  for (int n = 0; n < numNodes; ++n)
  {
    float x = m_mesh->nodeCoord(n, 0);
    float y = m_mesh->nodeCoord(n, 1);
    float z = m_mesh->nodeCoord(n, 2);
    float p = pnGlobal(n, i1);
    outfile << x << " " << y << " " << z << " " << p << "\n";
  }

  outfile.close();

  std::cout << "Saved snapshot to: " << filename.str() << std::endl;
}

void SEMproxy::export_ppm_xy_slice(int indexTimeSample)
{
  std::stringstream filename;
  std::filesystem::path dir = snap_folder_;

  if (!std::filesystem::exists(dir))
  {
    if (!std::filesystem::create_directory(dir))
    {
      std::cout << "Failed to create directory.\n";
    }
  }
  filename << snap_folder_ << "/heatmap_xy_" << indexTimeSample << ".ppm";
  int numNodes = m_mesh->getNumberOfNodes();

  std::ofstream outfile(filename.str());
  if (!outfile)
  {
    std::cerr << "Error: Could not open file " << filename.str() << std::endl;
    return;
  }

  int width = nb_elements_[0] * m_mesh->getOrder();
  int height = nb_elements_[1] * m_mesh->getOrder();

  outfile << "P3\n" << width << " " << height << "\n" << 255 << "\n";

  struct Pixel
  {
    int r = 0, g = 0, b = 0;
  };
  std::vector<std::vector<Pixel>> slice_pixels(height,
                                               std::vector<Pixel>(width));

  std::vector<float> all_pressures;
  float p_min = 0.0f, p_max = 0.0f;
  bool first = true;

  float min_coord1 = 0;
  float min_coord2 = 0;
  float spacing1 = m_mesh->getMinSpacing();
  float slice_coord = domain_size_[2] / 2.0f;

  for (int n = 0; n < m_mesh->getNumberOfNodes(); ++n)
  {
    if (std::abs(m_mesh->nodeCoord(n, 2) - slice_coord) < spacing1)
    {
      float p = pnGlobal(n, i1);
      all_pressures.push_back(p);
      if (first)
      {
        p_min = p;
        p_max = p;
        first = false;
      }
      else
      {
        if (p < p_min) p_min = p;
        if (p > p_max) p_max = p;
      }
    }
  }

  float abs_max = std::max(std::abs(p_min), std::abs(p_max));
  if (abs_max == 0.0f) abs_max = 1.0f;

  for (int n = 0; n < m_mesh->getNumberOfNodes(); ++n)
  {
    if (std::abs(m_mesh->nodeCoord(n, 2) - slice_coord) < spacing1)
    {
      int i = static_cast<int>(
          round((m_mesh->nodeCoord(n, 0) - min_coord1) / spacing1));
      int j = static_cast<int>(
          round((m_mesh->nodeCoord(n, 1) - min_coord2) / spacing1));

      if (i >= 0 && i < width && j >= 0 && j < height)
      {
        float p = pnGlobal(n, i1);
        float normalized_p = p / abs_max;
        slice_pixels[j][i].r =
            (normalized_p > 0.0f) ? static_cast<int>(255 * normalized_p) : 0;
        slice_pixels[j][i].b =
            (normalized_p < 0.0f) ? static_cast<int>(255 * -normalized_p) : 0;
      }
    }
  }

  for (int j = height - 1; j >= 0; --j)
  {
    for (int i = 0; i < width; ++i)
    {
      outfile << slice_pixels[j][i].r << " " << slice_pixels[j][i].g << " "
              << slice_pixels[j][i].b << "\n";
    }
  }
  outfile.close();
}

void SEMproxy::run()
{
  time_point<system_clock> startComputeTime, startOutputTime, totalComputeTime,
      totalOutputTime;

  SEMsolverDataAcoustic solverData(i1, i2, myRHSTerm, pnGlobal, rhsElement,
                                   rhsWeights);

  std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
  std::time_t now_c = std::chrono::system_clock::to_time_t(now);

  ofstream my_file;
  if (is_sismos_)
  {
    std::stringstream filename;
    std::filesystem::path dir = sismos_folder_;

    if (!std::filesystem::exists(dir))
    {
      if (!std::filesystem::create_directory(dir))
      {
        std::cout << "Failed to create directory.\n";
      }
    }
    filename << sismos_folder_ << "/sismos_res.sismos";

    my_file.open(filename.str());
    my_file << "Time ";
    for (int indexRcv = 0; indexRcv < nbReceivers; indexRcv++)
    {
      my_file << "" << rcvCoords(indexRcv, 0) << "," << rcvCoords(indexRcv, 1)
              << "," << rcvCoords(indexRcv, 2) << " ";
    }
    my_file << "\n";
  }

  for (int indexTimeSample = 0; indexTimeSample < num_sample_;
       indexTimeSample++)
  {
    startComputeTime = system_clock::now();
    m_solver->computeOneStep(dt_, indexTimeSample, solverData);
    totalComputeTime += system_clock::now() - startComputeTime;

    startOutputTime = system_clock::now();

    if (indexTimeSample % 50 == 0)
    {
      m_solver->outputSolutionValues(indexTimeSample, i1, rhsElement[0],
                                     pnGlobal, "pnGlobal");
      export_ppm_xy_slice(indexTimeSample);
    }
    if (is_snapshots_ && indexTimeSample % snap_time_interval_ == 0)
    {
      generate_snapshot(indexTimeSample);
    }

    // Save pressure at receiver
    const int order = m_mesh->getOrder();
    if (is_sismos_)
    {
      my_file << "t" << indexTimeSample << " ";
    }
    for (int indexRcv = 0; indexRcv < nbReceivers; indexRcv++)
    {
      float varnp1 = 0.0;
      for (int i = 0; i < order + 1; i++)
      {
        for (int j = 0; j < order + 1; j++)
        {
          for (int k = 0; k < order + 1; k++)
          {
            int nodeIdx =
                m_mesh->globalNodeIndex(rhsElementRcv[indexRcv], i, j, k);
            int globalNodeOnElement =
                i + j * (order + 1) + k * (order + 1) * (order + 1);
            varnp1 += pnGlobal(nodeIdx, i2) *
                      rhsWeightsRcv(indexRcv, globalNodeOnElement);
            // cout << "pn global " << pnGlobal(nodeIdx, i2) << "wheight"
            // <<rhsWeightsRcv(indexRcv, globalNodeOnElement) <<"\n";
          }
        }
      }

      pnAtReceiver(indexRcv, indexTimeSample) = varnp1;
      if (is_sismos_)
      {
        my_file << "" << varnp1 << " ";
      }
      // cout << "" <<varnp1<<" ";
    }
    swap(i1, i2);

    auto tmp = solverData.m_i1;
    solverData.m_i1 = solverData.m_i2;
    solverData.m_i2 = tmp;

    totalOutputTime += system_clock::now() - startOutputTime;
    if (is_sismos_)
    {
      my_file << "\n";
    }
    // cout << "\n";
  }
  if (is_sismos_)
  {
    my_file.close();
  }

  float kerneltime_ms = time_point_cast<microseconds>(totalComputeTime)
                            .time_since_epoch()
                            .count();
  float outputtime_ms =
      time_point_cast<microseconds>(totalOutputTime).time_since_epoch().count();

  cout << "------------------------------------------------ " << endl;
  cout << "\n---- Elapsed Kernel Time : " << kerneltime_ms / 1E6 << " seconds."
       << endl;
  cout << "---- Elapsed Output Time : " << outputtime_ms / 1E6 << " seconds."
       << endl;
  cout << "------------------------------------------------ " << endl;
}

// Initialize arrays
void SEMproxy::init_arrays()
{
  cout << "Allocate host memory for source and pressure values ..." << endl;

  rhsElement = allocateVector<vectorInt>(myNumberOfRHS, "rhsElement");
  rhsWeights = allocateArray2D<arrayReal>(
      myNumberOfRHS, m_mesh->getNumberOfPointsPerElement(), "RHSWeight");
  myRHSTerm = allocateArray2D<arrayReal>(myNumberOfRHS, num_sample_, "RHSTerm");
  pnGlobal =
      allocateArray2D<arrayReal>(m_mesh->getNumberOfNodes(), 2, "pnGlobal");
  pnAtReceiver =
      allocateArray2D<arrayReal>(nbReceivers, num_sample_, "pnAtReceiver");
  // Receiver
  // Allocate the vectors with the number of receivers
  rhsElementRcv = allocateVector<vectorInt>(nbReceivers, "rhsElementRcv");
  rhsWeightsRcv = allocateArray2D<arrayReal>(
      nbReceivers, m_mesh->getNumberOfPointsPerElement(), "RHSWeightRcv");
}

// Initialize sources
void SEMproxy::init_source()
{
  arrayReal myRHSLocation = allocateArray2D<arrayReal>(1, 3, "RHSLocation");
  // std::cout << "All source are currently are coded on element 50." <<
  // std::endl;
  std::cout << "All source are currently are coded on middle element."
            << std::endl;
  int ex = nb_elements_[0];
  int ey = nb_elements_[1];
  int ez = nb_elements_[2];

  int lx = domain_size_[0];
  int ly = domain_size_[1];
  int lz = domain_size_[2];

  // Get source element index

  int source_index = floor((src_coord_[0] * ex) / lx) +
                     floor((src_coord_[1] * ey) / ly) * ex +
                     floor((src_coord_[2] * ez) / lz) * ey * ex;

  for (int i = 0; i < 1; i++)
  {
    rhsElement[i] = source_index;
  }

  // Get coordinates of the corners of the sourc element
  float cornerCoords[8][3];
  int I = 0;
  int nodes_corner[2] = {0, m_mesh->getOrder()};
  for (int k : nodes_corner)
  {
    for (int j : nodes_corner)
    {
      for (int i : nodes_corner)
      {
        int nodeIdx = m_mesh->globalNodeIndex(rhsElement[0], i, j, k);
        cornerCoords[I][0] = m_mesh->nodeCoord(nodeIdx, 0);
        cornerCoords[I][2] = m_mesh->nodeCoord(nodeIdx, 2);
        cornerCoords[I][1] = m_mesh->nodeCoord(nodeIdx, 1);
        I++;
      }
    }
  }

  // initialize source term
  vector<float> sourceTerm =
      myUtils.computeSourceTerm(num_sample_, dt_, f0, sourceOrder);
  for (int j = 0; j < num_sample_; j++)
  {
    myRHSTerm(0, j) = sourceTerm[j];
    if (j % 100 == 0)
      cout << "Sample " << j << "\t: sourceTerm = " << sourceTerm[j] << endl;
  }

  // get element number of source term
  myElementSource = rhsElement[0];
  cout << "Element number for the source location: " << myElementSource << endl
       << endl;

  int order = m_mesh->getOrder();

  switch (order)
  {
    case 1:
      SourceAndReceiverUtils::ComputeRHSWeights<1>(cornerCoords, src_coord_,
                                                   rhsWeights);
      break;
    case 2:
      SourceAndReceiverUtils::ComputeRHSWeights<2>(cornerCoords, src_coord_,
                                                   rhsWeights);
      break;
    case 3:
      SourceAndReceiverUtils::ComputeRHSWeights<3>(cornerCoords, src_coord_,
                                                   rhsWeights);
      break;
    default:
      throw std::runtime_error("Unsupported order: " + std::to_string(order));
  }

  // Receiver computation
  for (int i = 0; i < nbReceivers; i++)
  {
    rhsElementRcv[i] = floor((rcvCoords(i, 0) * ex) / lx) +
                       floor((rcvCoords(i, 1) * ey) / ly) * ex +
                       floor((rcvCoords(i, 2) * ez) / lz) * ey * ex;
  }

  //  Get coordinates of the corners of the receiver element
  float cornerCoordsRcv[nbReceivers][8][3];
  for (int rcv = 0; rcv < nbReceivers; rcv++)
  {
    I = 0;
    for (int k : nodes_corner)
    {
      for (int j : nodes_corner)
      {
        for (int i : nodes_corner)
        {
          int nodeIdx = m_mesh->globalNodeIndex(rhsElementRcv[rcv], i, j, k);
          cornerCoordsRcv[rcv][I][0] = m_mesh->nodeCoord(nodeIdx, 0);
          cornerCoordsRcv[rcv][I][2] = m_mesh->nodeCoord(nodeIdx, 2);
          cornerCoordsRcv[rcv][I][1] = m_mesh->nodeCoord(nodeIdx, 1);
          I++;
        }
      }
    }
  }

  const int numNodes = m_mesh->getNumberOfPointsPerElement();
  arrayReal tmpWeights =
      allocateArray2D<arrayReal>(1, numNodes, "tmpRHSWeight");
  for (int i = 0; i < nbReceivers; i++)
  {
    std::array<float, 3> coords_tmp = {rcvCoords(i, 0), rcvCoords(i, 1),
                                       rcvCoords(i, 2)};
    switch (order)
    {
      case 1:
        SourceAndReceiverUtils::ComputeRHSWeights<1>(cornerCoordsRcv[i],
                                                     coords_tmp, tmpWeights);
        break;
      case 2:
        SourceAndReceiverUtils::ComputeRHSWeights<2>(cornerCoordsRcv[i],
                                                     coords_tmp, tmpWeights);
        break;
      case 3:
        SourceAndReceiverUtils::ComputeRHSWeights<3>(cornerCoordsRcv[i],
                                                     coords_tmp, tmpWeights);
        break;
      default:
        throw std::runtime_error("Unsupported order: " + std::to_string(order));
    }
    for (int n = 0; n < numNodes; ++n) rhsWeightsRcv(i, n) = tmpWeights(0, n);
  }
}

SolverFactory::implemType SEMproxy::getImplem(string implemArg)
{
  if (implemArg == "makutu") return SolverFactory::MAKUTU;
  if (implemArg == "shiva") return SolverFactory::SHIVA;

  throw std::invalid_argument(
      "Implentation type does not follow any valid type.");
}

SolverFactory::meshType SEMproxy::getMesh(string meshArg)
{
  if (meshArg == "cartesian") return SolverFactory::Struct;
  if (meshArg == "ucartesian") return SolverFactory::Unstruct;

  std::cout << "Mesh type found is " << meshArg << std::endl;
  throw std::invalid_argument("Mesh type does not follow any valid type.");
}

SolverFactory::methodType SEMproxy::getMethod(string methodArg)
{
  if (methodArg == "sem") return SolverFactory::SEM;
  if (methodArg == "dg") return SolverFactory::DG;

  throw std::invalid_argument("Method type does not follow any valid type.");
}

float SEMproxy::find_cfl_dt(float cfl_factor)
{
  float sqrtDim3 = 1.73;  // to change for 2d
  float min_spacing = m_mesh->getMinSpacing();
  float v_max = m_mesh->getMaxSpeed();

  float dt = cfl_factor * min_spacing / (sqrtDim3 * v_max);

  return dt;
}
