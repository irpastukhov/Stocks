//
//  SearchResultTableViewCell.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 21.07.2021.
//

import UIKit

/// Table view cell for search result
final class SearchResultTableViewCell: UITableViewCell {
    /// A string for identifying a reusable cell
    static let identifier = "SearchResultTableViewCell"
   
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
     
}
