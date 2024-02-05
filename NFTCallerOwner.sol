// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

contract NFTCaller {
    address public owner;
    error NotOwnerAuthorized();

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerAuthorized();
        _;
    }

    function updateOwner(address newowner) external onlyOwner {
        require(newowner != address(0), "Invalid Owner");
        owner = newowner;
    }

    function batchMintNFT(
        address[] calldata nftcontract,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external payable onlyOwner {
        require(receivers.length != 0, "please enter the acceptance address");
        require(nftcontract.length == amounts.length, "Unmatched length");
        require(amounts.length == receivers.length, "Unmatched length");
        bytes4 SELECTOR = bytes4(
            keccak256(bytes("nftcallermint(address,uint256)"))
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            (bool success, bytes memory data) = nftcontract[i].call(
                abi.encodeWithSelector(SELECTOR, receivers[i], amounts[i])
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "Transfer_Token_Faliled"
            );
        }
    }

    function ownerOf(address nftcontract, uint256 nftid)
        external
        view
        returns (address nftowner)
    {
        nftowner = IERC721A(nftcontract).ownerOf(nftid);
    }

    function nftIds(address nftcontract, address nftowner)
        external
        view
        returns (uint256[] memory ids)
    {
        ids = IERC721AQueryable(nftcontract).tokensOfOwner(nftowner);
    }

    function totalMinted(address nftcontract)
        external
        view
        returns (uint256 totalnfts)
    {
        totalnfts = IERC721AQueryable(nftcontract).totalSupply();
    }

    fallback() external payable {}

    receive() external payable {}
}
