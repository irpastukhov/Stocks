//
//  WatchViewController.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 20.07.2021.
//

import FloatingPanel
import UIKit

/// VC to render user watchlist
final class WatchlistViewController: UIViewController {
    
    /// Timer to optimize searching
    private var searchTimer: Timer?
    
    /// Floating news panel
    private var panel: FloatingPanelController?
    
    /// Width to track change label geometry
    static var maxChangeWidth: CGFloat = 0
    
    /// Main view to render watchlist
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(WatchlistTableViewCell.self, forCellReuseIdentifier: WatchlistTableViewCell.identifier)
        return table
    }()
    
    /// Observer for watchlist updates
    private var observer: NSObjectProtocol?
    
    /// Model
    private var watchlistMap = [String: [CandleStick]]()
    
    /// ViewModels
    private var viewModels = [WatchlistTableViewCell.ViewModel]()

    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setUpSearchController()
        setUpTableView()
        fetchWatchlistData()
        setUpTitleView()
        setUpFloatingPanel()
        setUpObserver()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - Private
    
    /// Sets up observer for watchlist updates
    private func setUpObserver() {
        observer = NotificationCenter.default.addObserver(
            forName: .didAddToWatchList,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.viewModels.removeAll()
                self?.fetchWatchlistData()
            }
        )
    }
    
    /// Fetch watchlist models
    private func fetchWatchlistData() {
        let symbols = PersistenceManager.shared.watchlist
        
        createPlaceholderViewModels()
        
        let group = DispatchGroup()
        
        for symbol in symbols where watchlistMap[symbol] == nil {
            group.enter()
            
            APICaller.shared.marketData(for: symbol) { [weak self] result in
                defer {
                    group.leave ()
                }
                switch result {
                case .success(let data):
                    self?.watchlistMap[symbol] = data.candleSticks
                case .failure(let error):
                    print(error)
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.createViewModels()
            self?.tableView.reloadData()
        }
    }
    
    private func createPlaceholderViewModels() {
        let symbols = PersistenceManager.shared.watchlist
        symbols.forEach { item in
            viewModels.append(
                .init(symbol: item,
                      companyName: UserDefaults.standard.string(forKey: item) ?? "Company",
                      price: "0.00",
                      changeColor: UIColor.gray,
                      changePercentage: "0.00",
                      chartViewModel: .init(data: [], showLegend: false, showAxis: false, fillColor: .clear))
            )
        }
        self.viewModels = viewModels.sorted(by: { $0.symbol < $1.symbol })
        tableView.reloadData()
    }
    
    /// Creates view models from models
    private func createViewModels() {
        var viewModels = [WatchlistTableViewCell.ViewModel]()
        
        for (symbol, candleSticks) in watchlistMap {
            let changePercentage = candleSticks.getPercentage()
            viewModels.append(
                .init(symbol: symbol,
                      companyName: UserDefaults.standard.string(forKey: symbol) ?? "Company",
                      price: getLatestClosingPrice(from: candleSticks),
                      changeColor: changePercentage < 0 ? .systemRed : .systemGreen,
                      changePercentage: .percentage(from: changePercentage),
                      chartViewModel:
                        .init(data: candleSticks.reversed().map { $0.close },
                              showLegend: false,
                              showAxis: false, fillColor: changePercentage < 0 ? .systemRed : .systemGreen)
                     )
            )
        }
        self.viewModels = viewModels.sorted(by: { $0.symbol < $1.symbol })
    }
    
    /// Gets latest closing price
    /// - Parameter data: Collection of data
    /// - Returns: String
    private func getLatestClosingPrice(from data: [CandleStick]) -> String {
        guard let closingPrice = data.first?.close else { return "" }
        return .formatted(number: closingPrice)
    }
    
    /// Sets up table view
    private func setUpTableView() {
        view.addSubviews(tableView)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    /// Sets up floating news panel
    private func setUpFloatingPanel() {
        let panel = FloatingPanelController(delegate: self)
        panel.surfaceView.backgroundColor = .secondarySystemBackground
        let vc = NewsViewController(dataType: .topStories)
        panel.set(contentViewController: vc)
        panel.track(scrollView: vc.tableView)
        panel.addPanel(toParent: self)
    }
    
    /// Set up custom title view
    private func setUpTitleView() {
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: navigationController?.navigationBar.height ?? 100))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: titleView.width - 20, height: titleView.height))
        label.text = "Stocks"
        label.font = UIFont.systemFont(ofSize: 37, weight: .medium)
        titleView.addSubview(label)
        
        navigationItem.titleView = titleView
    }
    
    /// Set up search and results controller
    private func setUpSearchController() {
        let resultVC = SearchResultsViewController()
        resultVC.delegate = self
        let searchVC = UISearchController(searchResultsController: resultVC)
        searchVC.searchResultsUpdater = self
        navigationItem.searchController = searchVC
    }
}

// MARK: - UISearchResultsUpdating

extension WatchlistViewController: UISearchResultsUpdating {
    /// Update search on key tap
    /// - Parameter searchController: Ref of the search controller
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text,
              let resultsVC = searchController.searchResultsController as? SearchResultsViewController,
              !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            APICaller.shared.search(query: query) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        resultsVC.update(with: response.result)
                    }
                case .failure(let error):
                    resultsVC.update(with: [])
                    print(error)
                }
            }
        }
    }
}

// MARK: - SearchResultsViewControllerDelegate

extension WatchlistViewController: SearchResultsViewControllerDelegate {
    /// Notify of search result selection
    /// - Parameter searchResult: Search result that was selected
    func searchResultsViewControllerDidSelect(searchResult: SearchResult) {
        HapticsManager.shared.vibrateForSelection()

        navigationItem.searchController?.searchBar.resignFirstResponder()
        let vc = StockDetailsViewController(
            symbol: searchResult.displaySymbol,
            companyName: searchResult.description)
        let navVC = UINavigationController(rootViewController: vc)
        vc.title = searchResult.description
        present(navVC, animated: true)
    }
}

// MARK: - FloatingPanelControllerDelegate

extension WatchlistViewController: FloatingPanelControllerDelegate {
    /// Gets floating panel state change
    /// - Parameter fpc: Ref of controller
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        navigationItem.titleView?.isHidden = fpc.state == .full
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension WatchlistViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: WatchlistTableViewCell.identifier,
            for: indexPath) as? WatchlistTableViewCell else {
            fatalError()
        }
        cell.delegate = self
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        HapticsManager.shared.vibrateForSelection()

        let viewModel = viewModels[indexPath.row]
        let vc = StockDetailsViewController(
            symbol: viewModel.symbol,
            companyName: viewModel.companyName,
            candleStickData: watchlistMap[viewModel.symbol] ?? [])
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            PersistenceManager.shared.removeFromWatchlist(symbol: viewModels[indexPath.row].symbol)
            viewModels.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
}

// MARK: - WatchlistTableViewCellDelegate

extension WatchlistViewController: WatchlistTableViewCellDelegate {
    /// Notify delegate of change label width
    func didUpdateMaxWidth() {
        tableView.reloadData()
    }
    
}
