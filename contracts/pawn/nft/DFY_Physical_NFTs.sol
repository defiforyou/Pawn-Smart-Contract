// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access/DFY-AccessControl.sol";
import "./IDFY_Physical_NFTs.sol";

contract DFY_Physical_NFTs is 
    IDFY_Physical_NFTs,
    Initializable,
    UUPSUpgradeable, 
    ERC1155Upgradeable, 
    DFYAccessControl, 
    PausableUpgradeable, 
    ERC1155BurnableUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    // Total NFT token
    CountersUpgradeable.Counter public totalToken;
    
    // Address evaluation
    address public evaluationContract;

    // Mapping list tokenId to CID
    // TokenId => CID
    mapping(uint256 => string) public tokenIdListToCID;

    // Mapping token id to information evaluation of NFT token 
    // TokenId => NFTEvaluation
    mapping (uint256 => NFTEvaluation) public tokenIdOfEvaluation; //evaluation Of Token

    // Mapping evaluator to NFT 
    // Address evaluator => listTokenId
    mapping (address => uint256[] ) public tokenIdListByEvaluator;

    // Struct NFT Evaluation
    // struct NFTEvaluation{
    //     address evaluationContract;
    //     uint256 evaluationId;
    // }

    // Name NFT token
    string public name;

    // Symbol NFT token
    string public symbol;

    // Base URI NFT Token
    string private _tokenBaseUri;

    // Event NFT create success
    event NFTCreated(
        address assetOwner,
        uint256 tokenID,
        string cid
    );

    // Modifier check contract valuation call mint NFT token
    modifier onlyEvaluation {
        require(msg.sender == evaluationContract, 'Cant mint.');
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __ERC1155_init("");
        __DFYAccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        
        _setBaseURI(_uri);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}


    function _setBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Blank baseURI");
        _tokenBaseUri = _uri;
    }

    function _baseURI() internal view returns (string memory) {
        return _tokenBaseUri;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return bytes(tokenIdListToCID[tokenId]).length > 0;
    }

    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_uri);
    }

    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid token");

        string memory baseUri = _baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenIdListToCID[tokenId])) : "";
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
    * @dev set address evaluation contract
    * @param _evaluationContract is address evaluation contract
    */
    function setEvaluationContract(address _evaluationContract) external onlyRole(DEFAULT_ADMIN_ROLE){
        // Check address different address(0)
        require(_evaluationContract != address(0), "Zero address.");

        // Check address is contract
        require(_evaluationContract.isContract(), "Not a contract.");

        // Set address evaluation
        evaluationContract = _evaluationContract;
    }

    /**
    * @dev evaluation contract call this function mint NFT token
    * @param _assetOwner is owner of asset mint NFT token
    * @param _evaluator is evaluator mint NFT
    * @param _evaluatontId is id evaluation NFT token
    * @param _amount is amount NFT token
    * @param _cid is cid of NFT token
    * @param _data is data of NFT token
    */
    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        override 
        onlyEvaluation 
        returns (uint256 tokenId)
    {
        // Gennerate tokenId
        tokenId = totalToken.current();

        // Add mapping tokenId to CID
        tokenIdListToCID[tokenId] = _cid;

        // Create NFT Evaluation and add to list
        tokenIdOfEvaluation[tokenId] = NFTEvaluation({
            evaluationContract: msg.sender,
            evaluationId: _evaluatontId
        });

        // Add tokenId to list tokenId by evaluator
        tokenIdListByEvaluator[_evaluator].push(tokenId);

        // Mint nft
        _mint(_assetOwner, tokenId, _amount, _data);

        // Update tokenId count
        totalToken.increment();

        emit NFTCreated(_assetOwner, tokenId, _cid);

        return tokenId;
    }

    /**
    * @dev get evaluation id and address of given token Id
    * @param _tokenId is the token whose evaluation data is being queried
    */
    function getEvaluationOfToken(uint256 _tokenId) 
        external 
        view
        override
        returns (address evaluationAddress, uint256 evaluationId) 
    {
        evaluationAddress   = tokenIdOfEvaluation[_tokenId].evaluationContract;
        evaluationId        = tokenIdOfEvaluation[_tokenId].evaluationId;
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) 
        internal 
        override whenNotPaused 
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function updateCID (uint256 _tokenId, string memory _newCID) external onlyRole(DEFAULT_ADMIN_ROLE){
        // Check for empty CID string input
        require(bytes(_newCID).length > 0, "Empty CID");

        // Check if token exists
        require(bytes(tokenIdListToCID[_tokenId]).length > 0, "Token doesn't exist");

        // Update CID
        tokenIdListToCID[_tokenId] = _newCID;
    }
}