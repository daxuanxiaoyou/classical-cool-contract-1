// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "hardhat/console.sol";

contract ClassicalNFT is
    ERC721,
    ERC2981,
    AccessControl,
    ReentrancyGuard,
    PullPayment
{
    using Counters for Counters.Counter;
    using ECDSA for bytes;
    using ECDSA for bytes32;

    Counters.Counter private currentTokenId;
    Counters.Counter private reserveTokenId;

    // roles
    // DEFAULT_ADMIN_ROLE = 0x00
    bytes32 public constant SWITCH_MINT_ROLE = keccak256("SWITCH_MINT_ROLE");
    bytes32 public constant FREE_MINT_ROLE = keccak256("FREE_MINT_ROLE");

    uint256 public constant reserveTokens = 100;
    uint256 public currentSupply = 0;

    // Constants
    uint256 public maxSupply = 99;
    // mint price
    uint256 public mintPrice = 0.0002 ether;

    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;
    // switch mint
    bool public isMintEnabled = true;
    address public public_key;

    // Public good address，未来安全阶梯给公益地址打款
    address public publicGoodAddress;

    // Treasury address，国库地址设置
    address public treasuryAddress;

    // ERC2981 royalty percentage (3%)
    uint256 public constant ROYALTY_PERCENTAGE = 3;

    /// store tokenid --> bookId
    mapping(uint256 => string) public tokenToBook;
    event Track(
        string indexed _function,
        address sender,
        uint256 value,
        bytes data
    );
    event AddPKSuccess(address pk, address whoAdd);

    modifier onlyWhiteList() {
        _checkRole(FREE_MINT_ROLE);
        _;
    }

    modifier onlySwitchRole() {
        _checkRole(SWITCH_MINT_ROLE);
        _;
    }

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    event MintEvent(
        address indexed user,
        uint256 indexed tokenId,
        string bookId
    );
    event SetMintPrice(uint256 indexed price);

    // name and symbol
    constructor() ERC721("Classical NFT Collectioin", "ClassicalNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SWITCH_MINT_ROLE, msg.sender);
    }

    // // ERC2981 implementation
    // function royaltyInfo(
    //     uint256,
    //     uint256 _salePrice
    // ) external view override returns (address receiver, uint256 royaltyAmount) {
    //     // Calculate royalty amount as a percentage of the sale price
    //     uint256 _royaltyAmount = _salePrice.mul(ROYALTY_PERCENTAGE).div(100);
    //     return (address(this), _royaltyAmount);
    // }

    //set addresses to whiteList
    function addToWhitelist(address[] calldata _addrArr) external onlyOwner {
        for (uint256 i = 0; i < _addrArr.length; i++) {
            _grantRole(FREE_MINT_ROLE, _addrArr[i]);
        }
    }

    function setPublicKey(address pk) public onlyOwner {
        public_key = pk;
        emit AddPKSuccess(pk, msg.sender);
    }

    function getPublickey() public view returns (address) {
        return public_key;
    }

    // TODO:need use internal
    function _verifyAddress(bytes memory signature) public view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(msg.sender));
        bytes32 dataHash = data.toEthSignedMessageHash();
        address recoverAdd = dataHash.recover(signature);
        return recoverAdd == public_key;
    }

    //remove addresses to whiteList
    function removeFromWhitelist(
        address[] calldata _addrArr
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrArr.length; i++) {
            _revokeRole(FREE_MINT_ROLE, _addrArr[i]);
        }
    }

    // set address to switchList
    function addToSwitchlist(address _switchAddress) external onlyOwner {
        _grantRole(SWITCH_MINT_ROLE, _switchAddress);
    }

    // remove address from switchList
    function removeFromSwitchList(address _switchAddress) external onlyOwner {
        _revokeRole(SWITCH_MINT_ROLE, _switchAddress);
    }

    // transfer admin
    function transferAdmin(address _newAdmin) external onlyOwner {
        //first grantRole
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        //then revoke self
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // swith mintable
    function toggleIsMintEnabled() external onlySwitchRole {
        isMintEnabled = !isMintEnabled;
    }

    /// the lowest price is 1e15 Wei
    function setMintPrice(uint256 _newPriceUnit) external onlyOwner {
        mintPrice = _newPriceUnit * 1e15;
        emit SetMintPrice(mintPrice);
    }

    function mint(
        address _recipient,
        string memory _bookId
    ) public payable nonReentrant returns (uint256) {
        require(isMintEnabled, "Minting not enabled");
        require(currentSupply <= maxSupply, "Max supply reached");

        // tokenId ++
        currentTokenId.increment();
        // reserve 100 NFTs from 1 ~ 100
        uint256 tokenId = currentTokenId.current() + reserveTokens;

        //if no free mint, pay eth
        if (!hasRole(FREE_MINT_ROLE, msg.sender)) {
            require(msg.value == mintPrice, "Please set the right value");
            //transfer eth to the contract
            _asyncTransfer(address(this), msg.value);
        }

        // mint nft
        _safeMint(_recipient, tokenId);
        tokenToBook[tokenId] = _bookId;
        currentSupply++;
        emit MintEvent(_recipient, tokenId, _bookId);
        return tokenId;
    }

    function mintReserve(
        address _recipient,
        string memory _bookId
    ) external onlyOwner returns (uint256) {
        require(isMintEnabled, "Minting not enabled");
        require(currentSupply <= maxSupply, "Max supply reached");

        // tokenId ++
        reserveTokenId.increment();
        // reserve 100 NFTs from 1 ~ 100
        uint256 tokenId = reserveTokenId.current();

        require(tokenId <= reserveTokens, "Max reserve reached");

        // mint nft
        _safeMint(_recipient, tokenId);
        tokenToBook[tokenId] = _bookId;
        currentSupply++;
        emit MintEvent(_recipient, tokenId, _bookId);
        return tokenId;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        return tokenId;
    }

    /// Sets max supply, one book one nft
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > currentSupply, "Must greate than current supply");
        maxSupply = _maxSupply;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(
        address payable _payee
    ) public virtual override onlyOwner {
        // 先取
        super.withdrawPayments(payable(address(this)));
        // 再转
        _payee.transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // receiver 搞一个版税地址
    function setDefaultRoyalty(uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(treasuryAddress, feeNumerator);
    }

    // function batchConfig(uint96 feeNumerator) public onlyOwner {
    //     super._setDefaultRoyalty(treasuryAddress, feeNumerator);
    // }

    fallback() external payable {
        emit Track("fallback()", msg.sender, msg.value, msg.data);
        revert();
    }

    receive() external payable {
        emit Track("receive()", msg.sender, msg.value, "");
    }
}
