import UIKit
import SnapKit
class StartViewController: UIViewController {
    var particleView: ParticleView!
    let progressBar = UIProgressView(progressViewStyle: .default)
    override func viewDidLoad() {
        super.viewDidLoad()
        particleView = ParticleView()
        view.addSubview(particleView)
        particleView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        self.view.addSubview(progressBar)
        progressBar.snp.makeConstraints { (make) in
            make.center.equalTo(self.view)
            make.width.equalTo(300)
            make.height.equalTo(20)
        }
        startProgressBar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.6) {
            let vc = ViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    private func startProgressBar() {
        var progress: Float = 0.0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            progress += 0.3
            self.progressBar.progress = progress

            switch progress {
            case 0.1...0.3:
                self.progressBar.progressTintColor = .red
            case 0.4...0.6:
                self.progressBar.progressTintColor = .green
            case 0.7...1.0:
                self.progressBar.progressTintColor = .blue
            default:
                break
            }
            if progress >= 1.0 {
                timer.invalidate()
            }
        }
    }
}
class ParticleView: UIView {
    var particleLayers = [CALayer]()
    override func layoutSubviews() {
        super.layoutSubviews()
        for layer in particleLayers {
            layer.removeFromSuperlayer()
        }
        particleLayers.removeAll()
        let particleCount = 90
        let particleRadius: CGFloat = 4
        let colors = [UIColor.red.cgColor, UIColor.green.cgColor, UIColor.blue.cgColor]
        for _ in 0..<particleCount {
            let particleLayer = CALayer()
            particleLayer.bounds = CGRect(x: 0, y: 0, width: particleRadius * 2, height: particleRadius * 2)
            particleLayer.position = CGPoint(x: CGFloat.random(in: 0..<bounds.width), y: CGFloat.random(in: 0..<bounds.height))
            particleLayer.cornerRadius = particleRadius
            particleLayer.backgroundColor = colors.randomElement()
            layer.addSublayer(particleLayer)
            particleLayers.append(particleLayer)
        }
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseInOut], animations: {
            for particleLayer in self.particleLayers {
                let originalPosition = particleLayer.position
                particleLayer.position = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: self.bounds.midX, y: self.bounds.midY))
                let endPoint = CGPoint(x: CGFloat.random(in: 0..<self.bounds.width), y: CGFloat.random(in: 0..<self.bounds.height))
                path.addLine(to: endPoint)
                path.addLine(to: originalPosition)
                let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
                animation.path = path.cgPath
                animation.duration = 5
                animation.timingFunctions = [CAMediaTimingFunction(name: .easeOut), CAMediaTimingFunction(name: .easeIn)]
                particleLayer.add(animation, forKey: "positionAnimation")
            }
        }, completion: nil)
    }
}
class ViewController: UIViewController, UISearchBarDelegate {
    let tableView = UITableView()
    let emptyStateImageView = UIImageView()
    let emptyStateLabel = UILabel()
    let viewModel = LoginViewModel()
    let searchBar = UISearchBar()
    var filteredProducts: [Login] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.logins = viewModel.loadLoginsFromUserDefaults()
        filteredProducts = viewModel.logins
        configureTableView()
        configureEmptyStateView()
        configureNavigationBar()
        updateEmptyStateViewVisibility()
        setupSearchBar()
    }
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
    }
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.direction = .left
        tableView.addGestureRecognizer(swipeGesture)
    }
    func configureEmptyStateView() {
        emptyStateImageView.image = UIImage(named: "page-removebg-preview")
        view.addSubview(emptyStateImageView)
        emptyStateImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(200)
        }
        emptyStateLabel.text = "Пока здесь ничего нет"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        emptyStateLabel.textColor = .black
        view.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(emptyStateImageView.snp.bottom).offset(20)
        }
    }
    func configureNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
        let deleteButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteButtonTapped))
        navigationItem.leftBarButtonItem = deleteButton
        navigationItem.title = "Список задач"
    }
    @objc func addButtonTapped() {
        let registrationVC = RegistrationViewController()
        registrationVC.delegate = self
        navigationController?.pushViewController(registrationVC, animated: true)
    }
    @objc func deleteButtonTapped() {
        if viewModel.logins.isEmpty {
            let alert = UIAlertController(title: "Еще пока нет аккаунтов", message: "Зарегистрируйтесь", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        } else {
            viewModel.logins.removeAll()
            filteredProducts.removeAll()
            tableView.reloadData()
            updateEmptyStateViewVisibility()
        }
    }
    @objc func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        if gesture.state == .ended {
            let gestureLocation = gesture.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: gestureLocation), indexPath.row < filteredProducts.count {
                let index = indexPath.row
                viewModel.deleteLogin(at: index)
                filteredProducts.remove(at: index)
                tableView.reloadData()
                updateEmptyStateViewVisibility()
            }
        }
    }
    func updateEmptyStateViewVisibility() {
        if filteredProducts.isEmpty {
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
        } else {
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
        }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredProducts = viewModel.logins.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil }
        tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredProducts = viewModel.logins
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let name = filteredProducts[indexPath.row]
        cell.textLabel?.text = "Аккаунт: \(name.name) Email: \(name.email) Пароль: \(name.password)"
        return cell
    }
}
extension ViewController: RegistrationViewControllerDelegate {
    func didRegisterUser(with name: String, email: String, password: String) {
        viewModel.createLogin(name: name, email: email, password: password)
        filteredProducts = viewModel.logins
        tableView.reloadData()
        updateEmptyStateViewVisibility()
    }
}
protocol RegistrationViewControllerDelegate: AnyObject {
    func didRegisterUser(with name: String, email: String, password: String)
}
class RegistrationViewController: UIViewController {
    weak var delegate: RegistrationViewControllerDelegate?
    let nameTextField = UITextField()
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    let viewModel = LoginViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigationBar()
        view.backgroundColor = .systemBackground
    }
    func configureUI() {
        nameTextField.placeholder = "Имя пользователя"
        nameTextField.borderStyle = .roundedRect
        view.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        emailTextField.placeholder = "Email"
        emailTextField.borderStyle = .roundedRect
        view.addSubview(emailTextField)
        emailTextField.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        passwordTextField.placeholder = "Пароль"
        passwordTextField.borderStyle = .roundedRect
        view.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(emailTextField.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        let generateButton = UIButton(type: .system)
        generateButton.setTitle("Сгенерировать пароль", for: .normal)
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        view.addSubview(generateButton)
        generateButton.snp.makeConstraints { make in
            make.top.equalTo(passwordTextField.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(generateButton.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
    }
    func configureNavigationBar() {
        navigationItem.title = "Регистрация"
    }
    @objc func generateButtonTapped() {
        let generatedPassword = viewModel.generatePassword()
        passwordTextField.text = generatedPassword
    }
    @objc func saveButtonTapped() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        if name.isEmpty || email.isEmpty || password.isEmpty {
            let alert = UIAlertController(title: "Ошибка", message: "Все поля должны быть заполнены", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        delegate?.didRegisterUser(with: name, email: email, password: password)
        navigationController?.popViewController(animated: true)
    }
}
