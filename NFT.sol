// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";

contract SC721 is ERC721A {
    address public owner;
    address public nftcaller;
    error NotOwnerAuthorized();
    error NotNFTCallercontract();

    constructor(
        string memory name,
        string memory symbol,
        address _nftcaller
    ) payable ERC721A(name, symbol) {
        owner = msg.sender;
        nftcaller = _nftcaller;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerAuthorized();
        _;
    }
    modifier onlynftCaller() {
        if (msg.sender != nftcaller) revert NotNFTCallercontract();
        _;
    }

    function updateOwner(address newowner) external onlyOwner {
        require(newowner != address(0), "Invalid Owner");
        owner = newowner;
    }

    function totalMinted() external view returns (uint256) {
        return _nextTokenId();
    }

    function updateNFTCaller(address newcaller) external onlyOwner {
        require(newcaller != address(0), "Invalid Owner");
        nftcaller = newcaller;
    }

    function mint(address receiver, uint256 amount) external {
        _mint(receiver, amount);
    }

    function nftcallermint(address receiver, uint256 amount)
        external
        onlynftCaller
    {
        _mint(receiver, amount);
    }
}
