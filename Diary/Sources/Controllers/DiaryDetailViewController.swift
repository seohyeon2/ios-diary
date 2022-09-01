//
//  DiaryDetailViewController.swift
//  Diary
//
//  Created by yeton, hyeon2 on 2022/08/18.
//

import UIKit

final class DiaryDetailViewController: UIViewController, CoreDataProcessing {
    var content: DiaryContents?
    var isExist: Bool = false

    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.keyboardDismissMode = .interactive
        textView.alwaysBounceVertical = true
        
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationItemTitle()
        configureLayout()
        registerForKeyboardShowNotification()
        registerForKeyboardHideNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTextView()
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textView.resignFirstResponder()
    }
    
    func getProcessedContent() -> [String] {
        var content = textView.text.components(separatedBy: "\n\n")
        
        if content.count >= 2 {
            return content
        }
        
        if content[0] == "\n" {
            content[0] = " "
        }
        
        content.append("")
        
        return content
    }
    
    private func configureNavigationItemTitle() {
        let time = content?.createdAt ?? Date().timeIntervalSince1970
        let date = Date(timeIntervalSince1970: time)
        
        navigationItem.title = DateFormatter.localizedString(
            from: date,
            dateStyle: .long,
            timeStyle: .none
        )
        
        navigationItem.rightBarButtonItem = .init(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: nil,
            action: #selector(showActionSheet)
        )
    }
    
    @objc private func showActionSheet(sender: AnyObject) {
        let actionSheet = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(
            title: "Share",
            style: .default,
            handler: { _ in
                self.showActivityView()
            }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Delete",
            style: .destructive,
            handler: { _ in
                self.showDeleteAlert()
            }))
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        
        present(
            actionSheet,
            animated: true
        )
    }
    
    private func showActivityView() {
        guard let content = self.content,
              let title = content.title else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [title],
            applicationActivities: nil
        )
        
        present(
            activityViewController,
            animated: true,
            completion: nil
        )
    }
    
    private func showDeleteAlert() {
        let action = UIAlertController(
            title: "진짜요?🥺",
            message: "정말로 삭제하시겠어요?🦦",
            preferredStyle: .alert
        )
        
        action.addAction(UIAlertAction(
            title: "취소",
            style: .cancel
        ))
        action.addAction(UIAlertAction(
            title: "삭제",
            style: .destructive,
            handler: { _ in
                guard let content = self.content else {
                    return
                }
                
                self.delete(content) { error in
                    DispatchQueue.main.async {
                        self.showErrorAlert(error: error)
                    }
                }
                self.navigationController?.popViewController(animated: true)
            }))
        
        present(
            action,
            animated: true
        )
    }
    
    private func configureLayout() {
        view.addSubview(textView)
        view.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            textView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            textView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            textView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            )
        ])
    }
    
    private func configureTextView() {
        guard let title = content?.title,
              let body = content?.body else {
            return
        }
        
        textView.text = title + "\n\n" + body
        textView.contentOffset.y = 0
    }
    
    private func registerForKeyboardShowNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showKeyBoard),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    @objc private func showKeyBoard(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? NSDictionary else {
            return
        }
        
        guard let keyboardFrame = userInfo.value(
            forKey: UIResponder.keyboardFrameEndUserInfoKey
        ) as? NSValue else {
            return
        }
        
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        textView.contentInset.bottom = keyboardHeight
    }
    
    private func registerForKeyboardHideNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveDiaryContents),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc func saveDiaryContents() {
        if textView.text.isEmpty == false && isExist == false {
            create(content: getProcessedContent()) { error in
                DispatchQueue.main.async {
                    self.showErrorAlert(error: error)
                }
            }
            
            guard let addedContent = getDiaryContent().last else {
                return
            }
            
            dataManager.snapshot.appendItems([addedContent])
        } else if textView.text.isEmpty == false && isExist == true {
            update(
                entity: content ?? DiaryContents(),
                content: getProcessedContent(),
                errorHandler: { error in
                    DispatchQueue.main.async {
                        self.showErrorAlert(error: error)
                    }
                })
            
            dataManager.snapshot.reloadItems(getDiaryContent())
        }
    }
}

extension DiaryDetailViewController: SendDataDelegate {
    func sendData<T>(
        _ data: T,
        isExist: Bool
    ) {
        content = data as? DiaryContents
        self.isExist = isExist
    }
}