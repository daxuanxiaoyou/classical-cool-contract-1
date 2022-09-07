// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClassicalBookNFT is ERC721, PullPayment, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    // Constants
    uint256 public maxSupply = 1;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    event mintEvent(uint256, string, address);

    // name and symbol
    constructor() ERC721("Classical Book NFT Collectioin", "ClassicalBook") {}

    function mintTo(address recipient, string memory bookId)
        public
        payable
        returns (uint256)
    {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < maxSupply, "Max supply reached");

        currentTokenId.increment();
        uint256 newTokenId = currentTokenId.current();
        emit mintEvent(newTokenId, bookId, recipient);
        _safeMint(recipient, newTokenId);
        return newTokenId;
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
        maxSupply = _maxSupply;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        uint256 tokenId = currentTokenId.current();
        return tokenId;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee)
        public
        virtual
        override
        onlyOwner
    {
        super.withdrawPayments(payee);
    }
}
