#include "testing/testing.hpp"

#include "map/transit/transit_display.hpp"

#include "indexer/data_source.hpp"

#include "base/strings_bundle.hpp"

#include <numeric>
#include <vector>

namespace transit_time_tests
{
namespace
{
TransitRouteInfo MakeRouteInfo(std::vector<double> const & times, std::vector<size_t> const & subrouteEnds)
{
  FrozenDataSource dataSource;
  TransitReadManager reader(dataSource, [](FeatureCallback const &, std::vector<FeatureID> const &) {},
                            [](m2::RectD const &) { return std::vector<MwmSet::MwmId>(); });
  StringsBundle const strings;
  std::map<std::string, m2::PointF> const symbols;
  TransitRouteDisplay display(reader, [](routing::NumMwmId) { return MwmSet::MwmId(); },
                              [&strings]() -> StringsBundle const & { return strings; }, nullptr, symbols);

  size_t begin = 0;
  for (auto const end : subrouteEnds)
  {
    std::vector<routing::RouteSegment> segments;
    for (size_t i = begin; i < end; ++i)
    {
      segments.emplace_back(routing::Segment(0, 0, i, true), routing::turns::TurnItem(),
                            geometry::PointWithAltitude({(i + 1) * 0.00001, 0}, 0),
                            routing::RouteSegment::RoadNameInfo());
      segments.back().SetDistancesAndTime(i + 1, (i + 1) * 0.00001, times[i]);
    }
    df::Subroute subroute;
    subroute.m_polyline.Add({begin * 0.00001, 0});
    TEST(display.ProcessSubroute(segments, subroute), (begin, end));
    begin = end;
  }
  TEST_EQUAL(begin, times.size(), ());
  return display.GetRouteInfo();
}
}  // namespace

UNIT_TEST(TransitDisplay_SegmentSplittingPreservesDuration)
{
  std::vector<double> times(1000);
  for (size_t i = 0; i < times.size(); ++i)
    times[i] = (i + 1) * 0.6;

  auto const info = MakeRouteInfo(times, {times.size()});
  TEST_EQUAL(info.m_totalTimeInSec, 600, ());
  TEST_EQUAL(info.m_totalPedestrianTimeInSec, 600, ());
  TEST_EQUAL(info.m_steps.size(), 1, ());
  TEST_EQUAL(info.m_steps.front().m_timeInSec, 600, ());
  TEST_EQUAL(info.m_totalPedestrianDistInMeters, 1000, ());

  std::vector<size_t> ends(times.size());
  std::iota(ends.begin(), ends.end(), 1);
  auto const splitInfo = MakeRouteInfo(times, ends);
  TEST_EQUAL(splitInfo.m_totalTimeInSec, info.m_totalTimeInSec, ());
  TEST_EQUAL(splitInfo.m_totalPedestrianTimeInSec, info.m_totalPedestrianTimeInSec, ());
  TEST_EQUAL(splitInfo.m_totalPedestrianDistInMeters, info.m_totalPedestrianDistInMeters, ());
  TEST_EQUAL(splitInfo.m_steps.size(), 2 * times.size() - 1, ());

  int total = 0;
  for (auto const & step : splitInfo.m_steps)
  {
    TEST_GREATER_OR_EQUAL(step.m_timeInSec, 0, ());
    if (step.m_type == TransitType::IntermediatePoint)
      TEST_EQUAL(step.m_timeInSec, 0, ());
    total += step.m_timeInSec;
  }
  TEST_EQUAL(total, 600, ());
}

UNIT_TEST(TransitDisplay_FractionalSubrouteBoundaries)
{
  auto const info = MakeRouteInfo({120.2, 1649.5}, {1, 2});
  TEST_EQUAL(info.m_totalTimeInSec, 1650, ());
  TEST_EQUAL(info.m_totalPedestrianTimeInSec, 1650, ());
  TEST_EQUAL(info.m_steps.size(), 3, ());
  TEST_EQUAL(info.m_steps[0].m_timeInSec, 121, ());
  TEST_EQUAL(info.m_steps[1].m_type, TransitType::IntermediatePoint, ());
  TEST_EQUAL(info.m_steps[1].m_intermediateIndex, 0, ());
  TEST_EQUAL(info.m_steps[1].m_timeInSec, 0, ());
  TEST_EQUAL(info.m_steps[2].m_timeInSec, 1529, ());

  auto const mergedInfo = MakeRouteInfo({120.2, 1649.5}, {2});
  TEST_EQUAL(mergedInfo.m_steps.front().m_timeInSec, info.m_totalTimeInSec, ());
  TEST_EQUAL(mergedInfo.m_totalPedestrianTimeInSec, info.m_totalPedestrianTimeInSec, ());
}

UNIT_TEST(TransitDisplay_WholeSecondTotals)
{
  struct Case
  {
    double m_seconds;
    int m_expected;
  };
  Case const cases[] = {{0.0, 0},    {0.9, 1},   {20.75, 21},    {59.99, 60},   {60.0, 60},
                        {89.99, 90}, {90.0, 90}, {1649.5, 1650}, {94485, 94485}};
  for (auto const & test : cases)
  {
    auto const info = MakeRouteInfo({test.m_seconds / 2, test.m_seconds}, {2});
    TEST_EQUAL(info.m_totalTimeInSec, test.m_expected, (test.m_seconds));
    TEST_EQUAL(info.m_totalPedestrianTimeInSec, test.m_expected, (test.m_seconds));
    TEST_EQUAL(info.m_steps.front().m_timeInSec, test.m_expected, (test.m_seconds));
  }
}
}  // namespace transit_time_tests
