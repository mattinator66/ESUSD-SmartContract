// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/security/ReentrancyGuard.sol";

// ESUSD: A T-bill backed stablecoin aiming for a $1 peg
contract ESUSD is ERC20, Pausable, Ownable, ReentrancyGuard {
    // Tracks frozen accounts for compliance/security (e.g., fraud prevention)
    mapping(address => bool) private _frozenAccounts;

    // Events for transparency and auditing
    event Minted(address indexed to, uint256 amount);
    event AccountFrozen(address indexed account, string reason);
    event AccountUnfrozen(address indexed account);
    event PausedByOwner(address indexed owner);
    event UnpausedByOwner(address indexed owner);

    // Initializes token with name and symbol
    constructor() ERC20("Electric Son USD", "ESUSD") {}

    // Mint new ESUSD matching T-bill reserves—owner only
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // Freeze an account with a reason (e.g., "suspected fraud")—owner only
    function freezeAccount(address account, string memory reason) external onlyOwner {
        require(account != address(0), "Cannot freeze zero address");
        require(account != owner(), "Cannot freeze contract owner");
        require(!_frozenAccounts[account], "Account already frozen");
        _frozenAccounts[account] = true;
        emit AccountFrozen(account, reason);
    }

    // Unfreeze an account—owner only
    function unfreezeAccount(address account) external onlyOwner {
        require(account != address(0), "Cannot unfreeze zero address");
        _frozenAccounts[account] = false;
        emit AccountUnfrozen(account);
    }

    // Check if an account is frozen—public view
    function isFrozen(address account) external view returns (bool) {
        return _frozenAccounts[account];
    }

    // Transfer ESUSD—blocked when paused
    function transfer(address to, uint256 amount) public whenNotPaused override returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        return super.transfer(to, amount);
    }

    // Transfer ESUSD from another account—reentrancy protected
    function transferFrom(address from, address to, uint256 amount) public nonReentrant whenNotPaused override returns (bool) {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        return super.transferFrom(from, to, amount);
    }

    // Increase spender allowance—blocked when paused
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused override returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    // Decrease spender allowance—blocked when paused
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused override returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    // Approve spender—blocked when paused
    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        return super.approve(spender, amount);
    }

    // Pause all transfers—owner only
    function pause() public onlyOwner {
        _pause();
        emit PausedByOwner(msg.sender);
    }

    // Unpause transfers—owner only
    function unpause() public onlyOwner {
        _unpause();
        emit UnpausedByOwner(msg.sender);
    }

    // Hook to enforce freeze/pause rules before transfers
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0)) { // Skip for minting
            require(!paused() || msg.sender == owner(), "Transfers paused except by owner");
            require(!_frozenAccounts[from], "Sender account is frozen");
            require(!_frozenAccounts[to], "Receiver account is frozen");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}