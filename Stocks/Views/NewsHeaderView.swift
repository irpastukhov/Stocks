//
//  NewsHeaderView.swift
//  Stocks
//
//  Created by Ivan Pastukhov on 22.07.2021.
//

import UIKit

/// Delegate for notifying header events
protocol NewsHeaderViewDelegate: AnyObject {
    /// Notify user tapped header button
    /// - Parameter headerView: Ref of header views
    func newsHeaderViewDidTapAddButton(_ headerView: NewsHeaderView)
}

/// Table view header fo news
final class NewsHeaderView: UITableViewHeaderFooterView {
    /// A string for identifying a reusable header
    static let identifier = "NewsHeaderView"
    
    /// Ideal height of header
    static let prefferedHeight: CGFloat = 70
    
    /// Delegate instance for events
    weak var delegate: NewsHeaderViewDelegate?
    
    /// View model for header view
    struct ViewModel {
        let title: String
        let shouldShowAddButton: Bool
    }
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        return label
    }()
    
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("+ Watchlist", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    // MARK: - Init
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubviews(label, button)
        contentView.backgroundColor = .secondarySystemBackground
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    /// Handle button tap
    @objc private func didTapButton() {
        delegate?.newsHeaderViewDidTapAddButton(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: 14,
                             y: 0,
                             width: contentView.width - 28,
                             height: contentView.height)
        
        button.sizeToFit()
        button.frame = CGRect(x: contentView.width - button.width - 16,
                              y: (contentView.height - button.height) / 2,
                              width: button.width + 8,
                              height: button.height)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
    
    // MARK: - Public
    
    /// Configure view
    /// - Parameter viewModel: view ViewModel
    public func configure(with viewModel: ViewModel) {
        label.text = viewModel.title
        button.isHidden = !viewModel.shouldShowAddButton
    }
    
}
