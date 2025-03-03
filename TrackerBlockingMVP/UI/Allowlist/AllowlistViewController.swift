//
//  BrowserViewController.swift
//  TrackerBlockingMVP
//
//  Created by FC on 24/2/25.
//

import UIKit
import SnapKit

protocol AllowlistViewControllerDelegate: AnyObject {
    /// Called when domains are removed from the allowlist
    /// - Parameter blockedDomains: A set of domains that have been blocked
    func allowlistDidUpdate(blockedDomains: Set<String>)
}

class AllowlistViewController: UITableViewController {
    private var allowlistedDomains: [String] = []
    private var selectedDomainsToBlock: Set<String> = []
    
    weak var delegate: AllowlistViewControllerDelegate?
    
    private lazy var editBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(enterEditMode))
    }()
    
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Block", style: .done, target: self, action: #selector(saveSelectedDomains))
        button.isEnabled = false
        return button
    }()
    
    private lazy var cancelBarButtonItem: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelAction))
        return button
    }()
    
    private let allowListManager: AllowlistManagerProtocol
    
    init(with allowListManager: AllowlistManagerProtocol) {
        self.allowListManager = allowListManager
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllowlistedDomains()
    }
    
    private func setupView() {
        title = NSLocalizedString("allowlist.title", comment: "")
        view.backgroundColor = .white
        
        // Set up navigation bar items
        navigationItem.rightBarButtonItem = editBarButtonItem
    }
    
    private func setupTableView() {
        tableView.register(AllowlistTableViewCell.self, forCellReuseIdentifier: "DomainCell")
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = UIView()
    }
    
    private func loadAllowlistedDomains() {
        allowlistedDomains = Array(allowListManager.getAllowlist()).sorted()
        tableView.reloadData()
    }
    
    @objc private func enterEditMode() {
        selectedDomainsToBlock.removeAll()
        tableView.setEditing(true, animated: true)
        cancelBarButtonItem.isEnabled = true
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        navigationItem.rightBarButtonItems = [saveBarButtonItem]
        updateSaveButtonState()
    }
    
    @objc private func saveSelectedDomains() {
        // Batch remove domains from allowlist
        guard !selectedDomainsToBlock.isEmpty else { return }
        
        for domain in selectedDomainsToBlock {
            allowListManager.removeFromAllowlist(domain: domain)
        }
        
        // Reload domains and exit edit mode
        loadAllowlistedDomains()
        tableView.setEditing(false, animated: true)
        navigationItem.rightBarButtonItem = editBarButtonItem

        // Notify delegate about changes with the batch of blocked domains
        delegate?.allowlistDidUpdate(blockedDomains: selectedDomainsToBlock)
        
        // Show confirmation
        showRemovalConfirmation()
    }
    
    @objc func cancelAction() {
        tableView.setEditing(false, animated: true)
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = [editBarButtonItem]
        updateSaveButtonState()
    }
    
    private func showRemovalConfirmation() {
        let message = selectedDomainsToBlock.count == 1
        ? NSLocalizedString("allowlist.one.domain.blocked.title", comment: "")
        : String(format: NSLocalizedString("allowlist.domains.blocked.title", comment: ""), selectedDomainsToBlock.count)
        
        let alert = UIAlertController(title: NSLocalizedString("allowlist.alert.title", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func updateSaveButtonState() {
        saveBarButtonItem.isEnabled = !selectedDomainsToBlock.isEmpty
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allowlistedDomains.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DomainCell", for: indexPath) as! AllowlistTableViewCell
        let domain = allowlistedDomains[indexPath.row]
        
        // Configure cell with current selection state
        cell.configure(with: domain, isSelected: selectedDomainsToBlock.contains(domain))
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.isEditing else { return }
        
        let selectedDomain = allowlistedDomains[indexPath.row]
        
        if selectedDomainsToBlock.contains(selectedDomain) {
            selectedDomainsToBlock.remove(selectedDomain)
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            selectedDomainsToBlock.insert(selectedDomain)
        }
        
        updateSaveButtonState()
    }
}
