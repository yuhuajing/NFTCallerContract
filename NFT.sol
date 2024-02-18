// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract SC721 is ERC721AQueryable {
    address public owner;
    address public miner;
    address public nftcaller;
    address public cosigner;
    uint256 expireTime;
    mapping(string => bool) sigvalue;
    uint256 public constant one_minute = 1 minutes;
    string baseurl;
    error notSatifiedSig();
    error NotOwnerAuthorized();
    error NotNFTCallercontract();
    error NotMineAuthorized();

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseurl,
        address _nftcaller,
        address _cosigner,
        address _miner,
        uint256 _expireTime
    ) payable ERC721A(name, symbol) {
        owner = msg.sender;
        nftcaller = _nftcaller;
        baseurl = _baseurl;
        cosigner = _cosigner;
        miner = _miner;
        expireTime = _expireTime * one_minute;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerAuthorized();
        _;
    }
    modifier onlynftCaller() {
        if (msg.sender != nftcaller) revert NotNFTCallercontract();
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

    function updateExpire(uint32 expire) external onlyOwner {
        expireTime = expire * one_minute;
    }

    function updateSigner(address newsigner) external onlyOwner {
        require(newsigner != address(0), "Invalid Signer");
        cosigner = newsigner;
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

    function ownerMint(address receiver, uint256 amount) external onlyMiner {
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

    function userMintNFT(bytes memory encodedsig) external {
        (address receiver, uint32 amount) = assertValidCosign(encodedsig);
        _mint(receiver, amount);
    }

    function assertValidCosign(bytes memory data)
        internal
        returns (address, uint32)
    {
        (
            address receivers,
            uint32 amounts,
            string memory requestId
        ) = _assertValidCosign(data);
        sigvalue[requestId] = true;
        return (receivers, amounts);
    }

    function _assertValidCosign(bytes memory data)
        public
        view
        returns (
            address,
            uint32,
            string memory
        )
    {
        (
            address receivers,
            uint32 amounts,
            string memory requestId,
            uint64 timestamp,
            bytes memory sig
        ) = decode(data);
        require((expireTime + timestamp >= block.timestamp), "HAS_Expired");
        require((!sigvalue[requestId]), "HAS_USED");

        if (
            !SignatureChecker.isValidSignatureNow(
                cosigner,
                getCosignDigest(
                    msg.sender,
                    receivers,
                    amounts,
                    _chainID(),
                    requestId,
                    timestamp
                ),
                sig
            )
        ) {
            revert notSatifiedSig();
        }
        return (receivers, amounts, requestId);
    }

    /**
     * @dev Returns data hash for the given sender, qty and timestamp.
     */
    function getCosignDigest(
        address sender,
        address receivers,
        uint32 amounts,
        uint32 chainId,
        string memory requestId,
        uint64 timestamp
    ) internal view returns (bytes32) {
        bytes32 _msgHash = keccak256(
            abi.encodePacked(
                address(this),
                sender,
                cosigner,
                receivers,
                amounts,
                chainId,
                requestId,
                timestamp
            )
        );
        return toEthSignedMessageHash(_msgHash);
    }

    /**
     * @dev Returns chain id.
     */
    function _chainID() public view returns (uint32) {
        uint32 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }

    function decode(bytes memory data)
        public
        pure
        returns (
            address receivers,
            uint32 amounts,
            string memory requestId,
            uint64 timestamp,
            bytes memory sig
        )
    {
        (, , , receivers, amounts, , requestId, timestamp, sig) = abi.decode(
            data,
            (
                address,
                address,
                address,
                address,
                uint32,
                uint32,
                string,
                uint64,
                bytes
            )
        );
    }

    function gettimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}
