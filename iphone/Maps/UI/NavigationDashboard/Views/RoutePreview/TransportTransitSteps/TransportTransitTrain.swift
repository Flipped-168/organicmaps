final class TransportTransitTrain: TransportTransitCell {
  enum Config {
    // A transit line supplies the badge color; keep its icon and number white in both themes.
    static let contentColor = UIColor.white
    static let labelTextFont = UIFont.bold12
    static let labelTrailing: CGFloat = 4
  }

  @IBOutlet private var background: UIView! {
    didSet {
      background.layer.setCornerRadius(.buttonSmall)
    }
  }

  @IBOutlet private var image: UIImageView! {
    didSet {
      image.tintColor = Config.contentColor
    }
  }

  @IBOutlet private var label: UILabel! {
    didSet {
      label.textColor = Config.contentColor
      label.font = Config.labelTextFont
    }
  }

  @IBOutlet private var labelTrailing: NSLayoutConstraint! {
    didSet {
      labelTrailing.constant = Config.labelTrailing
    }
  }

  @IBOutlet private var emptyNumberTrailingOffset: NSLayoutConstraint!

  override class func estimatedCellSize(step: MWMRouterTransitStepInfo) -> CGSize {
    let defaultSize = super.estimatedCellSize(step: step)
    let labelSize = step.number.size(width: CGFloat.greatestFiniteMagnitude, font: Config.labelTextFont, maxNumberOfLines: 1)
    return CGSize(width: defaultSize.width + labelSize.width + Config.labelTrailing, height: defaultSize.height)
  }

  override func config(step: MWMRouterTransitStepInfo) {
    switch step.type {
    case .intermediatePoint, .pedestrian, .ruler: fatalError()
    case .train: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_train")
    case .subway: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_metro")
    case .lightRail: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_lightrail")
    case .monorail: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_monorail")
    case .tram, .cableTram: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_tram")
    case .bus: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_bus")
    case .ferry, .waterService: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_ferry")
    case .aerialLift: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_aerial_lift")
    case .funicular: image.image = #imageLiteral(resourceName: "ic_20px_route_planning_funicular")
    case .airService: image.image = #imageLiteral(resourceName: "ic_bm_airport").withRenderingMode(.alwaysTemplate)
    }
    background.backgroundColor = step.color

    emptyNumberTrailingOffset.isActive = step.number.isEmpty
    label.isHidden = step.number.isEmpty
    label.text = step.number
  }
}
