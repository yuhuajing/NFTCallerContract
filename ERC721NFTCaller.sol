// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTCaller {
    address public owner;
    address public miner;
    error NotOwnerAuthorized();
    error NotMineAuthorized();

    constructor(address _owner, address _miner) payable {
        owner = _owner;
        miner = _miner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerAuthorized();
        _;
    }
    modifier onlyMiner() {
        if (msg.sender != miner) revert NotMineAuthorized();
        _;
    }

    function updateOwner(address newowner) external onlyOwner {
        require(newowner != address(0), "Invalid Owner");
        owner = newowner;
    }

    function updateMiner(address newminer) external onlyOwner {
        require(newminer != address(0), "Invalid miner");
        miner = newminer;
    }

    function batchMintNFT(
        address[] calldata nftcontract,
        address[] calldata receivers,
        uint256[][] calldata nftIds
    ) external payable onlyMiner {
        require(receivers.length != 0, "please enter the acceptance address");
        require(nftcontract.length == nftIds.length, "Unmatched length");
        require(nftIds.length == receivers.length, "Unmatched length");
        bytes4 SELECTOR = bytes4(
            keccak256(bytes("nftcallermint(address,uint256[])"))
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            (bool success, bytes memory data) = nftcontract[i].call(
                abi.encodeWithSelector(SELECTOR, receivers[i], nftIds[i])
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "Transfer_Token_Faliled"
            );
        }
    }

    function ownerOf(IERC721 nftcontract, uint256 nftid)
        external
        view
        returns (address nftowner)
    {
        nftowner = nftcontract.ownerOf(nftid);
    }

    fallback() external payable {}

    receive() external payable {}
}
