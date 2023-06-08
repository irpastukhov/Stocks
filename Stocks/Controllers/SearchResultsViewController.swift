//
//  SearchResultsViewController.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 20.07.2021.
//

import UIKit


/// Delegate for search results
protocol SearchResultsViewControllerDelegate: AnyObject {
    /// Notify delegate of selection
    /// - Parameter searchResult: Result that was picked
    func searchResultsViewControllerDidSelect(searchResult: SearchResult)
}

/// VC to show search results
final class SearchResultsViewController: UIViewController {
    
    /// Delegate to get events
    weak var delegate: SearchResultsViewControllerDelegate?
    
    /// Collection of results
    private var results = [SearchResult]()
    
    /// Primary views
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        table.isHidden = true
        return table
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        
    }
    
    // MARK: - Private
    
    private func setUpTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    // MARK: - Public
    
    /// Update results on VC
    /// - Parameter results: Collection of new results
    public func update(with results: [SearchResult]) {
        self.results = results
        tableView.isHidden = results.isEmpty
        tableView.reloadData()
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath)
        
        let result = results[indexPath.row]
        
        cell.textLabel?.text = result.displaySymbol
        cell.detailTextLabel?.text = result.description
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = results[indexPath.row]
        delegate?.searchResultsViewControllerDidSelect(searchResult: result)
    }
    
}
