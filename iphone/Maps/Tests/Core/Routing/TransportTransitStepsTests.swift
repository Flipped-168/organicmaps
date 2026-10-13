@testable import Organic_Maps__Debug_
import XCTest

final class TransportTransitStepsTests: XCTestCase {
  private let transportTypes: [MWMRouterTransitType] = [
    .subway, .train, .lightRail, .monorail, .tram, .bus,
    .ferry, .cableTram, .aerialLift, .funicular, .airService, .waterService,
  ]

  func testTransportCellsKeepIconsNumbersAndColors() throws {
    for style in [UIUserInterfaceStyle.light, .dark] {
      let collection = TransportTransitStepsCollectionView(layout: TransportTransitFlowLayout())
      collection.frame = CGRect(x: 0, y: 0, width: 1000, height: 200)
      collection.steps = transportTypes.map { makeStep(type: $0, number: "12") }
      let controller = UIViewController()
      controller.overrideUserInterfaceStyle = style
      controller.view.addSubview(collection)
      let window = UIWindow(frame: collection.frame)
      window.rootViewController = controller
      window.isHidden = false
      defer { window.isHidden = true }
      collection.layoutIfNeeded()

      for (index, type) in transportTypes.enumerated() {
        let cell = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: index, section: 0)))
        XCTAssertTrue(cell is TransportTransitTrain, "\(type)")
        let views = descendants(of: cell.contentView)
        let icon = try XCTUnwrap(views.compactMap { $0 as? UIImageView }.first)
        let label = try XCTUnwrap(views.compactMap { $0 as? UILabel }.first)
        XCTAssertNotNil(icon.image, "\(type)")
        XCTAssertGreaterThan(icon.image?.size.width ?? 0, 0, "\(type)")
        XCTAssertGreaterThan(icon.image?.size.height ?? 0, 0, "\(type)")
        XCTAssertEqual(icon.tintColor, .white)
        XCTAssertEqual(icon.superview?.backgroundColor, collection.steps[index].color)
        XCTAssertEqual(label.text, "12")
        XCTAssertEqual(label.textColor, .white)
        XCTAssertFalse(label.isHidden)
      }

      let renderer = UIGraphicsImageRenderer(bounds: collection.bounds)
      let attachment = XCTAttachment(image: renderer.image { context in
        UIColor.systemBackground.resolvedColor(with: collection.traitCollection).setFill()
        context.fill(collection.bounds)
        collection.layer.render(in: context.cgContext)
      })
      attachment.name = "Transit cells - \(style == .light ? "light" : "dark")"
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }

  func testTransportCellRecoversWhenLineNumberChanges() throws {
    let cell = try XCTUnwrap(UINib(nibName: "TransportTransitTrain", bundle: .main)
      .instantiate(withOwner: nil).first as? TransportTransitTrain)
    let views = descendants(of: cell.contentView)
    let label = try XCTUnwrap(views.compactMap { $0 as? UILabel }.first)
    let icon = try XCTUnwrap(views.compactMap { $0 as? UIImageView }.first)

    for type in transportTypes {
      cell.config(step: makeStep(type: type, number: ""))
      XCTAssertTrue(label.isHidden)
      XCTAssertNotNil(icon.image, "\(type)")
      cell.config(step: makeStep(type: type, number: "F1"))
      XCTAssertFalse(label.isHidden)
      XCTAssertEqual(label.text, "F1")
      XCTAssertNotNil(icon.image, "\(type)")
    }
  }

  func testWalkingWaypointsAndRulerKeepTheirCells() throws {
    let types: [MWMRouterTransitType] = [.pedestrian, .intermediatePoint, .ruler]
    let collection = TransportTransitStepsCollectionView(layout: TransportTransitFlowLayout())
    collection.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
    collection.steps = types.map { makeStep(type: $0, number: "") }
    collection.layoutIfNeeded()
    let walking = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: 0, section: 0)))
    let waypoint = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: 1, section: 0)))
    let ruler = try XCTUnwrap(collection.cellForItem(at: IndexPath(item: 2, section: 0)))
    XCTAssertTrue(walking is TransportTransitPedestrian)
    XCTAssertTrue(waypoint is TransportTransitIntermediatePoint)
    XCTAssertTrue(ruler is TransportRuler)
  }

  private func makeStep(type: MWMRouterTransitType, number: String) -> MWMRouterTransitStepInfo {
    let step = MWMRouterTransitStepInfo()
    step.type = type
    step.number = number
    step.distance = "42"
    step.distanceUnits = "m"
    step.color = UIColor(red: 47 / 255, green: 100 / 255, blue: 153 / 255, alpha: 1)
    step.intermediateIndex = 2
    return step
  }

  private func descendants(of view: UIView) -> [UIView] {
    view.subviews.flatMap { [$0] + descendants(of: $0) }
  }
}
