// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract NFTConteact is ERC721 {
    address public owner;
    address public miner;
    address public nftcaller;
    address public cosigner;
    uint256 public expireTime;
    mapping(string => bool) sigvalue;
    uint256 public constant ONE_MINUTE = 1 minutes;
    string baseurl;
    uint256[] public mintedNFT;
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
    ) payable ERC721(name, symbol) {
        owner = msg.sender;
        nftcaller = _nftcaller;
        baseurl = _baseurl;
        cosigner = _cosigner;
        miner = _miner;
        expireTime = _expireTime * ONE_MINUTE;
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
        expireTime = expire * ONE_MINUTE;
    }

    function updateSigner(address newsigner) external onlyOwner {
        require(newsigner != address(0), "Invalid Signer");
        cosigner = newsigner;
    }

    function updateBaseURL(string memory _baseurl) external onlyOwner {
        require(bytes(_baseurl).length != 0, "Invalid baseurl");
        baseurl = _baseurl;
    }

    function updateNFTCaller(address newcaller) external onlyOwner {
        require(newcaller != address(0), "Invalid Owner");
        nftcaller = newcaller;
    }

    function mintable(uint256 tokenId) public view returns (bool) {
        uint256 nftSize = mintedNFT.length;
        for (uint256 i = 0; i < nftSize; i++) {
            if (mintedNFT[i] == tokenId) {
                return false;
            }
        }
        return true;
    }

    function mintedNFTs() external view returns (uint256, uint256[] memory) {
        return (mintedNFT.length, mintedNFT);
    }

    function minerMint(address receiver, uint256 nftId) external onlyMiner {
        require(mintable(nftId), "AlreadyMintedOrBurned");
        _mint(receiver, nftId);
        mintedNFT.push(nftId);
    }

    function nftcallermint(address receiver, uint256 nftId)
        external
        onlynftCaller
    {
        require(mintable(nftId), "AlreadyMintedOrBurned");
        _mint(receiver, nftId);
        mintedNFT.push(nftId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        _requireOwned(tokenId);
        return
            bytes(baseurl).length != 0
                ? string(abi.encodePacked(baseurl, _toString(tokenId), ".json"))
                : "";
    }

    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    function userMintNFT(bytes memory encodedsig) external {
        (address receiver, uint32 nftId) = assertValidCosign(encodedsig);
        require(mintable(nftId), "AlreadyMintedOrBurned");
        _mint(receiver, nftId);
        mintedNFT.push(nftId);
    }

    function burn(uint256 tokenId) external virtual {
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        _update(address(0), tokenId, _msgSender());
    }

    function assertValidCosign(bytes memory data)
        internal
        returns (address, uint32)
    {
        (
            address receivers,
            uint32 nftId,
            string memory requestId
        ) = _assertValidCosign(data);
        sigvalue[requestId] = true;
        return (receivers, nftId);
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
            uint32 nftId,
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
                    nftId,
                    _chainID(),
                    requestId,
                    timestamp
                ),
                sig
            )
        ) {
            revert notSatifiedSig();
        }
        return (receivers, nftId, requestId);
    }

    /**
     * @dev Returns data hash for the given sender, qty and timestamp.
     */
    function getCosignDigest(
        address sender,
        address receivers,
        uint32 nftId,
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
                nftId,
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
            uint32 nftId,
            string memory requestId,
            uint64 timestamp,
            bytes memory sig
        )
    {
        (, , , receivers, nftId, , requestId, timestamp, sig) = abi.decode(
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
