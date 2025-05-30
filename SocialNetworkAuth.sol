// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SocialNetworkAuth {
    // Структура для хранения данных пользователя
    struct User {
        string username;
        string encryptedEmail;
        string profileHash; // IPFS или другой хэш профиля
        uint256 registrationDate;
        bool isActive;
    }
    
    // Маппинги для хранения данных
    mapping(address => User) private users;
    mapping(string => address) private usernameToAddress;
    mapping(address => bool) private registeredAddresses;
    
    // Администратор контракта
    address public owner;
    
    // События для отслеживания действий
    event UserRegistered(address indexed userAddress, string username, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, string newProfileHash);
    event AccountDeactivated(address indexed userAddress);
    event AccountReactivated(address indexed userAddress);
    
    // Модификаторы доступа
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(registeredAddresses[msg.sender], "User not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Функция регистрации нового пользователя
    function registerUser(
        string memory _username,
        string memory _encryptedEmail,
        string memory _profileHash
    ) external {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_encryptedEmail).length > 0, "Email cannot be empty");
        require(usernameToAddress[_username] == address(0), "Username already taken");
        require(!registeredAddresses[msg.sender], "Address already registered");
        
        users[msg.sender] = User({
            username: _username,
            encryptedEmail: _encryptedEmail,
            profileHash: _profileHash,
            registrationDate: block.timestamp,
            isActive: true
        });
        
        usernameToAddress[_username] = msg.sender;
        registeredAddresses[msg.sender] = true;
        
        emit UserRegistered(msg.sender, _username, block.timestamp);
    }
    
    // Получение данных пользователя
    function getUser(address _userAddress) external view returns (
        string memory username,
        string memory encryptedEmail,
        string memory profileHash,
        uint256 registrationDate,
        bool isActive
    ) {
        require(registeredAddresses[_userAddress], "User not found");
        User memory user = users[_userAddress];
        return (
            user.username,
            user.encryptedEmail,
            user.profileHash,
            user.registrationDate,
            user.isActive
        );
    }
    
    // Обновление профиля
    function updateProfile(string memory _newProfileHash) external onlyRegistered {
        require(bytes(_newProfileHash).length > 0, "Profile hash cannot be empty");
        users[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newProfileHash);
    }
    
    // Деактивация аккаунта
    function deactivateAccount() external onlyRegistered {
        users[msg.sender].isActive = false;
        emit AccountDeactivated(msg.sender);
    }
    
    // Реактивация аккаунта
    function reactivateAccount() external onlyRegistered {
        users[msg.sender].isActive = true;
        emit AccountReactivated(msg.sender);
    }
    
    // Проверка существования пользователя
    function isUserRegistered(address _userAddress) external view returns (bool) {
        return registeredAddresses[_userAddress];
    }
    
    // Получение адреса по имени пользователя
    function getAddressByUsername(string memory _username) external view returns (address) {
        return usernameToAddress[_username];
    }
    
    // Функция только для владельца - экстренная блокировка
    function adminDeactivate(address _userAddress) external onlyOwner {
        require(registeredAddresses[_userAddress], "User not found");
        users[_userAddress].isActive = false;
        emit AccountDeactivated(_userAddress);
    }
}