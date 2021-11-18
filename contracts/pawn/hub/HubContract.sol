// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access/DFY-AccessControl.sol";
import "../nft/IDFY_Physical_NFTs.sol";

import "../evaluation/IBEP20.sol";

contract PawnNFTModel is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable,
    DFYAccessControl
{
    mapping(address => uint256) public whitelistCollateral;
    address public feeWallet;
    uint256 public penaltyRate;
    uint256 public systemFeeRate;
    uint256 public lateThreshold;
    uint256 public prepaidFeeRate;
    uint256 public ZOOM;
    address public admin;
    address public operator;

    // DFY_Physical_NFTs dfy_physical_nfts;
    // AssetEvaluation assetEvaluation;

    function initialize(uint256 _zoom) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        admin = address(msg.sender);
        ZOOM = _zoom;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setOperator(address _newOperator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // operator = _newOperator;
        operator = _newOperator;
        grantRole(OPERATOR_ROLE, _newOperator);
    }

    function setFeeWallet(address _newFeeWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        feeWallet = _newFeeWallet;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the transaction
     */
    function setSystemFeeRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        systemFeeRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _feeRate is percentage of tokens to pay for the penalty
     */
    function setPenaltyRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        penaltyRate = _feeRate;
    }

    /**
     * @dev set fee for each token
     * @param _threshold is number of time allowed for late repayment
     */
    function setLateThreshold(uint256 _threshold)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint256 _feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelistCollateral[_token] = _status;
    }

    // function emergencyWithdraw(address _token)
    //     external
    //     whenPaused
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     PawnNFTLib.safeTransfer(
    //         _token,
    //         address(this),
    //         msg.sender,
    //         PawnNFTLib.calculateAmount(_token, address(this))
    //     );
    // }

    // /** ===================================== REPUTATION FUNCTIONS & STATES ===================================== */

    // IReputation public reputation;

    // function setReputationContract(address _reputationAddress)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     reputation = IReputation(_reputationAddress);
    // }

    // mapping(uint256 => address) public ListContract;

    // address reputation;

    // function setReputationContract(address _reputationAddress)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     reputation = _reputationAddress;
    // }

    // // /**==========================   ExchangeRate   ========================= */
    // // Exchange public exchange;

    // // function setExchangeRate(address _exchange)
    // //     external
    // //     onlyRole(DEFAULT_ADMIN_ROLE)
    // // {
    // //     exchange = Exchange(_exchange);
    // // }

    // address exchange;

    // function setExchangeRate(address _exchange)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     exchange = _exchange;
    // }

    mapping(bytes4 => address) ListContract;

    function register(bytes4 _signature, address _contractAddress) external {
        ListContract[_signature] = _contractAddress;
    }
}