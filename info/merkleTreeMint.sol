// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Modifier 'onlyOwner' becomes available, where owner is the contract deployer
 */
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev ERC721 token standard
 */
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/**
 * @dev Merkle tree
 */
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract ETHomes is Ownable, ERC721Enumerable { 


    uint256 public maxSupply = 9; // 8000;
    uint256 public maxPreSaleMintTotal = 4; // 6000;
    uint256 public cost = 0.1 ether;

    uint256 public preSaleTimestamp = 1646211600; // March 2nd, 9am PST (March 2nd, 5pm UTC)
    uint256 public publicSaleTimestamp = 1646254800; // March 2nd, 9pm PST (March 3rd, 5am UTC)
    
    uint256 private preSaleMints;
    uint256 private v1HomeTotal;
    uint256 private upgradedHomeTotal;

    bool public upgradeStatus;

    string public baseTokenURI;
    string public  placeholderURI;

    bytes32 root; 
    

    constructor( 
        string memory _preRevealURI,
        string memory _placeholderURI
    ) ERC721("ETHomes", "HOME") {
        baseTokenURI = _preRevealURI;
        placeholderURI = _placeholderURI;
    }
    
    
    // --- EVENTS ---
    
    event TokenMinted(uint256 tokenId);
    event UpgradeRequest(uint256 tokenId1, uint256 tokenId2, address user, uint256 newTokenId);
    
    
    // --- MAPPINGS ---
    
    mapping(address => uint) whitelistMintNumber; // tracks number of tokens each whitelisted address has minted
    mapping(uint => string) tokenURImap;

        
    // --- PUBLIC ---
    
    
    /**
     * @dev Mint tokens through pre or public sale
     */
    function mint() external payable {

        require(block.timestamp >= publicSaleTimestamp, "Public sale not live");
        
        require(msg.value == cost, "Incorrect funds supplied"); // mint cost
        require(v1HomeTotal + 1 <= maxSupply, "All tokens have been minted");
        
        require(balanceOf(msg.sender) + 1 <= 8, "Maximum of 8 tokens per wallet");
        
        uint tokenId = v1HomeTotal + 1;  
        _mint(msg.sender, tokenId);
        v1HomeTotal ++;
        emit TokenMinted(tokenId);
        
    }

    function whitelistMint(bytes32[] memory _proof) external payable {
        
        require(block.timestamp >= preSaleTimestamp && block.timestamp < publicSaleTimestamp, "Presale not live");
        require(msg.value == cost, "Incorrect funds supplied"); // mint cost
        require(v1HomeTotal + 1 <= maxSupply, "All tokens have been minted");
        require(whitelistMintNumber[msg.sender] < 3, "Maximum of 3 per address allowed at pre sale");
        require(preSaleMints + 1 <= maxPreSaleMintTotal, "Minting would exceed total pre sale mint allocation"); 
        
        require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))) == true, "Not on whitelist");

        preSaleMints += 1;
        whitelistMintNumber[msg.sender]++;

        uint tokenId = v1HomeTotal + 1;  
        _mint(msg.sender, tokenId);
        v1HomeTotal ++;
        emit TokenMinted(tokenId);
        
    }
    
    
    function upgrade(uint _tokenId1, uint _tokenId2) external {

        require(upgradeStatus, "Home upgrades are not available yet");
        require(ownerOf(_tokenId1) == msg.sender && ownerOf(_tokenId2) == msg.sender, "You do not own one or more of these tokens");

        _burn(_tokenId1);
        _burn(_tokenId2);

        uint tokenId = (8001 + upgradedHomeTotal);
        _mint(msg.sender, tokenId);
        upgradedHomeTotal ++;
        tokenURImap[tokenId] = placeholderURI;

        // store burned tokenId's for admin 

        emit UpgradeRequest(_tokenId1, _tokenId2, msg.sender, tokenId);
    }
    
    
    
    // --- VIEW ---
    
    
    /**
     * @dev Returns tokenURI, which, if revealedStatus = true, is comprised of the baseURI concatenated with the tokenId
     */
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(tokenURImap[_tokenId]).length == 0) {
            return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
        } else {
            return tokenURImap[_tokenId];
        }
     
    }


    

    // --- ONLY OWNER ---

    function upgradeCallback(uint _tokenId, address _tokenOwner, string memory _tokenURI) external onlyOwner() {
        require(ownerOf(_tokenId) == _tokenOwner, "_tokenId / _tokenOwner mismatch");
        tokenURImap[_tokenId] = _tokenURI;
    }

    /**
     * @dev Set the upgradability status 
     * @param _status - boolean of whether upgrading is live
     */
    function setUpgradeStatus(bool _status) external onlyOwner {
        upgradeStatus = _status;
    }
    
    /**
     * @dev Withdraw all ether from smart contract. Only contract owner can call.
     * @param _to - address ether will be sent to
     */
    function withdrawAllFunds(address payable _to) external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        _to.transfer(address(this).balance);
    }

    /**
     * @dev Withdraw ether from smart contract. Only contract owner can call.
     * @param _amount - amount of ether to withdraw (unit: Wei)
     * @param _to - address ether will be sent to
     */
    function withdrawFunds(uint _amount, address payable _to) external onlyOwner {
        require(_amount <= address(this).balance, "Withdrawal amount greater than smart contract balance");
        _to.transfer(_amount);
    }
    
    
    
    /**
     * @dev Airdrop 1 token to each address in array '_to'
     * @param _to - array of address' that tokens will be sent to
     */
    function airDrop(address[] calldata _to) external onlyOwner {

        require(totalSupply() + _to.length <= maxSupply, "Minting this many would exceed total supply");

        for (uint i=0; i<_to.length; i++) {
            uint tokenId = totalSupply() + 1;
            _mint(_to[i], tokenId);
            emit TokenMinted(tokenId);
        }
        
    }


    /**
     * @dev Set the baseURI string. Can be used for image reveal.
     */
    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseTokenURI = _newBaseUri;
    }


    /**
     * @dev Set the placeholderURI string.
     */
    function setPlaceholderURI(string memory _newPlaceholderURI) external onlyOwner {
        placeholderURI = _newPlaceholderURI;
    }
    
    
    /**
     * @dev Set the cost of minting a token
     * @param _newCost in Wei. Where 1 Wei = 10^-18 ether
     */
    function setCost(uint _newCost) external onlyOwner {
        cost = _newCost;
    }
    
    
    /**
     * @dev Set the status of the pre sale, sets publicSaleStatus to false
     * @param _timestamp - unix timestamp (UTC) of new preSale start time
     */
    function setPreSaleTimestamp(uint _timestamp) external onlyOwner {
        preSaleTimestamp = _timestamp;
    }
    
    
    /**
     * @dev Set the status of the public sale, sets preSaleStatus to false
     * @param _timestamp - unix timestamp (UTC) of new publicSale start time
     */
    function setPublicSaleTimestamp(uint _timestamp) external onlyOwner {
        publicSaleTimestamp = _timestamp;
    }


    /**
     * @dev Set the root for Merkle Proof
     */
    function setRoot(bytes32 _newRoot) external onlyOwner {
        root = _newRoot;
    }
    
}