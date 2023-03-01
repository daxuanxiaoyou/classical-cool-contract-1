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

// TODO: 721AA
// TODO: 721AA
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

    uint256 totalBalance;

    uint256 public constant reserveTokens = 100; // TODO:设置大一点？中间有一段数据可以空出来
    uint256 public currentSupply = 0;

    // Constants
    uint256 public maxSupply = 99;
    // mint price
    uint256 public mintPrice = 0.0002 ether;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    // switch mint
    bool public isMintEnabled = true;
    address public public_key;

    // TODO:Public good address，未来阶梯给公益地址打款
    address public publicGoodAddress;

    // TODO: Treasury address，国库地址设置
    address public treasuryAddress;

    // TODO 定期多签捐赠，把捐赠资金锁定 vincent

    /// store tokenid --> bookId
    mapping(uint256 => string) public tokenToBook;
    mapping(string => bool) public bookList;
    string[] public bookIds;
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
        string bookId,
        address indexed sender
    );
    event SetMintPrice(uint256 indexed price);

    // name and symbol
    constructor(
        address _treasuryAddress,
        address _publicGoodAddress,
        uint96 feeNumerator
    ) ERC721("Classical NFT Collectioin", "ClassicalNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SWITCH_MINT_ROLE, msg.sender);
        treasuryAddress = _treasuryAddress;
        publicGoodAddress = _publicGoodAddress;
        setDefaultRoyalty(feeNumerator);
    }

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

    // TODO:need use internal
    function _verifySignMsg(
        bytes memory signature,
        string memory _bookId
    ) public view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(msg.sender, _bookId));
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
    // TODO: 避免转移错了地址，分步骤进行，先设置缓存地址，缓存地址完成一笔交易，再成为正式 admin
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
    // TODO:测试一下
    function setMintPrice(uint256 _newPriceUnit) external onlyOwner {
        mintPrice = _newPriceUnit * 1e15;
        emit SetMintPrice(mintPrice);
    }

    function mint(
        address _recipient,
        string memory _bookId,
        bytes memory signature
    ) public payable nonReentrant returns (uint256) {
        require(isMintEnabled, "Minting not enabled");
        require(currentSupply <= maxSupply, "Max supply reached");
        require(!bookList[_bookId], "Book id exist");
        // TODO: chainID、contract Address,防止重放
        require(
            _verifySignMsg(signature, _bookId),
            "Verify sign message is fail, please check _bookId or signature message."
        );

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
        // TODO:没有退款，是否单独搞一个 freemint function，lee 给模板

        // mint nft
        _safeMint(_recipient, tokenId);
        tokenToBook[tokenId] = _bookId;
        bookList[_bookId] = true;
        bookIds.push(_bookId);
        currentSupply++;
        totalBalance += msg.value;
        emit MintEvent(_recipient, tokenId, _bookId, msg.sender);
        return tokenId;
    }

    function getBookList() public view returns (string[] memory) {
        return bookIds;
    }

    function mintReserve(
        address _recipient,
        string memory _bookId
    ) external nonReentrant onlyOwner returns (uint256) {
        require(isMintEnabled, "Minting not enabled");
        require(currentSupply <= maxSupply, "Max supply reached");
        require(!bookList[_bookId], "Book id exist");

        // tokenId ++
        reserveTokenId.increment();
        // reserve 100 NFTs from 1 ~ 100

        uint256 tokenId = reserveTokenId.current();

        // TODO, 只能在100以内才行，会超出范围
        require(tokenId <= reserveTokens, "Max reserve reached");

        // mint nft
        _safeMint(_recipient, tokenId);
        tokenToBook[tokenId] = _bookId;
        bookList[_bookId] = true;
        bookIds.push(_bookId);
        currentSupply++;
        emit MintEvent(_recipient, tokenId, _bookId, msg.sender);
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

    /// Sets max supply, one book one nft
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply > currentSupply, "Must greate than current supply");
        maxSupply = _maxSupply;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    // TODO: ERC20 的 transfer
    function withdrawPayments(
        address payable
    ) public virtual override onlyOwner {
        // 先取
        super.withdrawPayments(payable(address(this)));

        //现获取公益比例
        uint256 percentage = getDonateRate();

        //先转公益地址
        payable(publicGoodAddress).transfer(
            (address(this).balance * percentage) / 100
        );
        //再转国库地址
        payable(treasuryAddress).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        // address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        // TODO: 直接到国库，会导致 donate 无法计算，_asynctransfer 的地址和 receiver 不一样？
        _setTokenRoyalty(tokenId, address(this), feeNumerator);
    }

    // receiver 搞一个版税地址
    // TODO: 同上
    function setDefaultRoyalty(uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(address(this), feeNumerator);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setPublicGoodAddress(
        address _publicGoodAddress
    ) external onlyOwner {
        publicGoodAddress = _publicGoodAddress;
    }

    receive() external payable {
        totalBalance += msg.value;
        emit Track("receive()", msg.sender, msg.value, "");
    }

    function getDonateRate() public view returns (uint256) {
        uint256 percentage = 0;

        // 计算应捐赠的金额
        if (totalBalance < 10 ether) {
            percentage = 10;
        } else if (totalBalance > 10 && totalBalance < 100 ether) {
            percentage = 20;
        } else if (totalBalance > 100 && totalBalance < 1000 ether) {
            percentage = 30;
        } else if (totalBalance > 1000 && totalBalance < 10000 ether) {
            percentage = 40;
        } else if (totalBalance > 10000 && totalBalance < 100000 ether) {
            percentage = 50;
        } else if (totalBalance > 100000 && totalBalance < 1000000 ether) {
            percentage = 60;
        } else if (totalBalance > 1000000 && totalBalance < 10000000 ether) {
            percentage = 70;
        } else if (totalBalance > 10000000 && totalBalance < 100000000 ether) {
            percentage = 80;
        } else {
            percentage = 90;
        }
        return percentage;
    }
}
