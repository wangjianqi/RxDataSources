//
//  ViewController.swift
//  Example
//
//  Created by Krunoslav Zaher on 1/1/16.
//  Copyright © 2016 kzaher. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import CoreLocation

class NumberCell : UICollectionViewCell {
    @IBOutlet private var value: UILabel?

    func configure(with value: String) {
        self.value?.text = value
    }
}

class NumberSectionView : UICollectionReusableView {
    @IBOutlet private weak var value: UILabel?

    func configure(value: String) {
        self.value?.text = value
    }
}

class PartialUpdatesViewController: UIViewController {

    @IBOutlet private weak var animatedTableView: UITableView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var animatedCollectionView: UICollectionView!
    @IBOutlet private weak var refreshButton: UIButton!

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        //初始值
        let initialRandomizedSections = Randomizer(rng: PseudoRandomGenerator(4, 3), sections: initialValue())
        //interval:每隔一段时间发出一个索引数
        let ticks = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).map { _ in () }
        let randomSections = Observable.of(ticks, refreshButton.rx.tap.asObservable())
            //合并成一个
                .merge()
            //
                .scan(initialRandomizedSections) { a, _ in
                    return a.randomize()
                }
                .map { a in
                    return a.sections
                }
            .share(replay: 1)

        let (configureCell, titleForSection) = PartialUpdatesViewController.tableViewDataSourceUI()
        //配置
        let tvAnimatedDataSource = RxTableViewSectionedAnimatedDataSource<NumberSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        //配置
        let reloadDataSource = RxTableViewSectionedReloadDataSource<NumberSection>(
            configureCell: configureCell,
            titleForHeaderInSection: titleForSection
        )
        //绑定
        randomSections
            .bind(to: animatedTableView.rx.items(dataSource: tvAnimatedDataSource))
            .disposed(by: disposeBag)
        //绑定
        randomSections
            .bind(to: tableView.rx.items(dataSource: reloadDataSource))
            .disposed(by: disposeBag)

        let (configureCollectionViewCell, configureSupplementaryView) =  PartialUpdatesViewController.collectionViewDataSourceUI()
        //配置CollectionView
        let cvAnimatedDataSource = RxCollectionViewSectionedAnimatedDataSource(
            configureCell: configureCollectionViewCell,
            configureSupplementaryView: configureSupplementaryView
        )
        //绑定
        randomSections
            .bind(to: animatedCollectionView.rx.items(dataSource: cvAnimatedDataSource))
            .disposed(by: disposeBag)

        // touches

        Observable.of(
            tableView.rx.modelSelected(IntItem.self),
            animatedTableView.rx.modelSelected(IntItem.self),
            animatedCollectionView.rx.modelSelected(IntItem.self)
        )
            .merge()
            .subscribe(onNext: { item in
                print("Let me guess, it's .... It's \(item), isn't it? Yeah, I've got it.")
            })
            .disposed(by: disposeBag)
    }
}

// MARK: Skinning
extension PartialUpdatesViewController {
    //配置tableView
    static func tableViewDataSourceUI() -> (
        TableViewSectionedDataSource<NumberSection>.ConfigureCell,
        TableViewSectionedDataSource<NumberSection>.TitleForHeaderInSection
    ) {
        return (
            { _, tv, ip, i in
                let cell = tv.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style:.default, reuseIdentifier: "Cell")
                cell.textLabel!.text = "\(i)"
                return cell
            },
            { ds, section -> String? in
                return ds[section].header
            }
        )
    }

    static func collectionViewDataSourceUI() -> (
            CollectionViewSectionedDataSource<NumberSection>.ConfigureCell,
            CollectionViewSectionedDataSource<NumberSection>.ConfigureSupplementaryView
        ) {
        return (
             { _, cv, ip, i in
                let cell = cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: ip) as! NumberCell
                cell.configure(with: "\(i)")
                return cell

            },
             { ds ,cv, kind, ip in
                let section = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Section", for: ip) as! NumberSectionView
                section.configure(value: "\(ds[ip.section].header)")
                return section
            }
        )
    }

    // MARK: Initial value
    //初始值
    func initialValue() -> [NumberSection] {
        #if true
            let nSections = 10
            let nItems = 100


            /*
            let nSections = 10
            let nItems = 2
            */

            return (0 ..< nSections).map { (i: Int) in
                NumberSection(header: "Section \(i + 1)", numbers: `$`(Array(i * nItems ..< (i + 1) * nItems)), updated: Date())
            }
        #else
            return _initialValue
        #endif
    }


}

let _initialValue: [NumberSection] = [
    NumberSection(header: "section 1", numbers: `$`([1, 2, 3]), updated: Date()),
    NumberSection(header: "section 2", numbers: `$`([4, 5, 6]), updated: Date()),
    NumberSection(header: "section 3", numbers: `$`([7, 8, 9]), updated: Date()),
    NumberSection(header: "section 4", numbers: `$`([10, 11, 12]), updated: Date()),
    NumberSection(header: "section 5", numbers: `$`([13, 14, 15]), updated: Date()),
    NumberSection(header: "section 6", numbers: `$`([16, 17, 18]), updated: Date()),
    NumberSection(header: "section 7", numbers: `$`([19, 20, 21]), updated: Date()),
    NumberSection(header: "section 8", numbers: `$`([22, 23, 24]), updated: Date()),
    NumberSection(header: "section 9", numbers: `$`([25, 26, 27]), updated: Date()),
    NumberSection(header: "section 10", numbers: `$`([28, 29, 30]), updated: Date())
]
//函数
func `$`(_ numbers: [Int]) -> [IntItem] {
    return numbers.map { IntItem(number: $0, date: Date()) }
}

