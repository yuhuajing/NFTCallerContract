// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract SC721 is ERC721AQueryable {
    address public owner;
    address public nftcaller;
    string baseurl;
    error NotOwnerAuthorized();
    error NotNFTCallercontract();

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseurl,
        address _nftcaller
    ) payable ERC721A(name, symbol) {
        owner = msg.sender;
        nftcaller = _nftcaller;
        baseurl = _baseurl;
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

    function updateBaseURL(string memory _baseurl) external onlyOwner {
        require(bytes(_baseurl).length != 0, "Invalid baseurl");
        baseurl = _baseurl;
    }

    function totalMinted() external view returns (uint256) {
        return _nextTokenId();
    }

    function updateNFTCaller(address newcaller) external onlyOwner {
        require(newcaller != address(0), "Invalid Owner");
        nftcaller = newcaller;
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    function nftcallermint(address receiver, uint256 amount)
        external
        onlynftCaller
    {
        _mint(receiver, amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseurl).length != 0
                ? string(abi.encodePacked(baseurl, _toString(tokenId), ".json"))
                : "";
    }
}
