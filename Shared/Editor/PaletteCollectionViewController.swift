import UIKit
import SpritePencilKit

protocol PaletteDelegate: AnyObject {
	func selectedColorDidChange(colorComponents components: ColorComponents)
}

class PaletteCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, RecentColorDelegate {
    
    #if targetEnvironment(macCatalyst)
    static let itemMinLength: CGFloat = 20.0
    static let itemMaxLength: CGFloat = 30.0
    #else
    static let itemMinLength: CGFloat = 30.0
    static let itemMaxLength: CGFloat = 42.0
    #endif
    
	weak var paletteDelegate: PaletteDelegate!
    
    var colors = [ColorComponents]()
    var recentColors = [ColorComponents]()
    let maxRecentColorCount = 16
    var sectionInsetLength: CGFloat!
    var itemSize: CGSize!
    var messagesAppMode = false
    var showClearColor = false
    var selectedColor = ColorComponents(red: 0, green: 0, blue: 0, opacity: 255)
    
    convenience init() {
        #if targetEnvironment(macCatalyst)
        let insetLength: CGFloat = 8.0
        #else
        let insetLength: CGFloat = 20.0
        #endif
        let flow = UICollectionViewFlowLayout()
        flow.minimumLineSpacing = 2.0
        flow.minimumInteritemSpacing = 0.0
        flow.sectionInset = UIEdgeInsets(top: insetLength, left: insetLength, bottom: insetLength, right: insetLength)
        let itemLength = PaletteCollectionViewController.itemMinLength
        let itemSize = CGSize(width: itemLength, height: itemLength)
        flow.itemSize = itemSize
        self.init(collectionViewLayout: flow)
        self.sectionInsetLength = insetLength
        self.itemSize = itemSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dragDelegate = self
        collectionView.register(PaletteColorCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .clear // Not system background, because of iMessage app
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshCellSize(size: view.bounds.size)
    }
    
    func loadPalette(_ palette: Palette) {
        colors = palette.colors
        collectionView.reloadData()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return messagesAppMode ? 1 : (showClearColor ? 3 : 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let topInsetLength = (section == 0) ? sectionInsetLength! : 0.0
        return UIEdgeInsets(top: topInsetLength, left: sectionInsetLength, bottom: sectionInsetLength, right: sectionInsetLength)
    }
    
    func colorsForSection(at section: Int) -> [ColorComponents] {
        if !messagesAppMode, section == 0 {
            return recentColors
        } else if section == 2 {
            return [.clear]
        }
        return colors
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorsForSection(at: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PaletteColorCell
        let color = colorsForSection(at: indexPath.section)[indexPath.item]
        
        cell.colorView.backgroundColor = UIColor(components: color)
//        if cell.traitCollection.userInterfaceStyle == .dark {
            if color.red < 30, color.green < 30, color.blue < 30 {
                cell.colorView.layer.borderColor = UIColor.opaqueSeparator.cgColor
                cell.colorView.layer.borderWidth = 0.5
            } else {
                cell.colorView.layer.borderWidth = 0.0
            }
//        }
        cell.layer.borderColor = UIColor(named: "Brand")?.cgColor
        cell.layer.borderWidth = (color == selectedColor) ? 2.0 : 0.0
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 2.0
        selectedColor = colorsForSection(at: indexPath.section)[indexPath.item]
        paletteDelegate.selectedColorDidChange(colorComponents: selectedColor)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let colorComponents = colorsForSection(at: indexPath.section)[indexPath.item]
        let provider = NSItemProvider(object: UIColor(components: colorComponents))
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = colorComponents
        dragItem.previewProvider = {
            let cell = collectionView.cellForItem(at: indexPath) as! PaletteColorCell
            return UIDragPreview(view: cell.colorView)
        }
        return [dragItem]
    }
    
    func usedColor(components: ColorComponents) {
        guard components.opacity == 255 else { return }
        // Move to front
        if let index = recentColors.firstIndex(of: components) {
            if index != 0 {
                recentColors.insert(recentColors.remove(at: index), at: 0)
                collectionView.moveItem(at: IndexPath(item: index, section: 0), to: IndexPath(item: 0, section: 0))
            }
            return
        }
        
        var toolColor: UIColor?
        if let oldIndexPath = collectionView.indexPathsForSelectedItems?.first, oldIndexPath.item < colorsForSection(at: oldIndexPath.section).count {
            toolColor = UIColor(components: colorsForSection(at: oldIndexPath.section)[oldIndexPath.item])
        }
        
        recentColors.insert(components, at: 0)
        if maxRecentColorCount < recentColors.count {
            recentColors.removeLast()
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: [IndexPath(item: maxRecentColorCount-1, section: 0)])
                collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
            }, completion: nil)
        } else {
            collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        }
        
        if (UIColor(components: components) != toolColor) {
            if let indexPath = collectionView.indexPathsForSelectedItems?.first, indexPath.section == 0 {
                let newIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
                if newIndexPath.item < maxRecentColorCount {
                    collectionView.selectItem(at: newIndexPath, animated: true, scrollPosition: .centeredVertically)
                } else {
                    collectionView.deselectItem(at: indexPath, animated: true)
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard !messagesAppMode else { return }
        refreshCellSize(size: size)
    }
    
    func refreshCellSize(size: CGSize) {
        let insetLength: CGFloat
        let mimimumItemsPerRow: Int
        #if targetEnvironment(macCatalyst)
        insetLength = 8.0
        mimimumItemsPerRow = 8
        #else
        switch size.width {
        case ..<280:
            insetLength = 8.0
            mimimumItemsPerRow = 4
        case 280..<320:
            insetLength = 16.0
            mimimumItemsPerRow = 6
        default:
            insetLength = 20.0
            mimimumItemsPerRow = 8
        }
        #endif
        var itemLength = floor(size.width - (insetLength * 2.0)) / CGFloat(mimimumItemsPerRow)
        itemLength = min(max(PaletteCollectionViewController.itemMinLength, itemLength), PaletteCollectionViewController.itemMaxLength)
        itemSize = CGSize(width: itemLength, height: itemLength)
        sectionInsetLength = insetLength
        collectionView.reloadData()
    }

}
