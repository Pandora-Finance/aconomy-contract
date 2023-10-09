// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/Libraries/LibCalculations.sol";
import "contracts/poolRegistry.sol";
import "contracts/FundingPool.sol";
import "contracts/AconomyFee.sol";
import "contracts/utils/sampleERC20.sol";

contract FundingPoolTest is Test {
    poolRegistry PoolRegistry;
    SampleERC20 erc20Contract;
    FundingPool fundingPool;
    AconomyFee aconomyFee;
    AttestationServices attestationServices;
    AttestationRegistry attestationRegistry;

    uint256 public paymentCycleDuration;
    uint256 public loanDefaultDuration;
    uint256 public loanExpirationDuration;

    address payable alice = payable(address(0xABCC));
    address payable sam = payable(address(0xABDD));
    address payable bob = payable(address(0xABCD));
    address payable adya = payable(address(0xABDE));

    uint256 erc20Amount = 10000000000;
    uint256 maxLoanDuration = 90;
    uint16 apr = 10;

    uint256 poolId;

    address poolAdd;


    // Event public e;

    event SupplyToPool(
        address indexed lender,
        uint256 indexed poolId,
        uint256 BidId,
        address indexed ERC20Token,
        uint256 tokenAmount
    );


    function setUp() public {
        attestationRegistry = new AttestationRegistry();
        attestationServices = new AttestationServices(attestationRegistry);

        PoolRegistry = new poolRegistry(
            attestationServices,
            address(aconomyFee)
        );
        aconomyFee = new AconomyFee();
        erc20Contract = new SampleERC20();

        fundingPool = new FundingPool(
            address(this), // _poolOwner
            address(this), // _poolRegistry
            3600, // _paymentCycleDuration
            30, // _paymentDefaultDuration
            5 // _feePercent
        );

        // e = new event();
    }

    function test_CreatePool() public {
        vm.prank(alice);
        poolId = PoolRegistry.createPool(
            3600,
            1800,
            86400,
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "adya.com",
            false,
            false
        );

        poolAdd = PoolRegistry.getPoolAddress(1);


    
    }

    function test_supplyToPool() public {
        test_CreatePool();
       
erc20Contract.mint(bob, 100000);
        vm.prank(bob);

        

        erc20Contract.approve(address(poolAdd), 100000);
        vm.prank(bob);

        FundingPool(address(poolAdd)).supplyToPool(
            poolId,
            address(erc20Contract),
            100000,
            uint32(maxLoanDuration),
            apr,
            block.timestamp + 3600
        );
        
    }
      function test_CreateNewPool() public {
        vm.prank(alice);
        poolId = PoolRegistry.createPool(
            3600,
            1800,
            86400,
            1000, // Pool fee percent (e.g., 10%)
            500, // APR (e.g., 5%)
            "adya.com",
            true,
            false
        );

        poolAdd = PoolRegistry.getPoolAddress(1);


    
    }
    function test_AddLender() external {
test_CreateNewPool();

    
assertEq(poolId, 1, "something wromg");
vm.prank(alice);
PoolRegistry.addLender(poolId, bob, block.timestamp + 3600);

    (bool isVerified, ) = PoolRegistry.lenderVarification(poolId, bob);
    assertEq(isVerified, true, "Lender not added successfully");
}
 function test_supplyToPool2() public {
        test_CreatePool();
       
erc20Contract.mint(adya, 100000);
        vm.prank(adya);

        

        erc20Contract.approve(address(poolAdd), 100000);
        vm.prank(adya);

        FundingPool(address(poolAdd)).supplyToPool(
            poolId,
            address(erc20Contract),
            100000,
            uint32(maxLoanDuration),
            apr,
            block.timestamp + 3600
        );
}
function test_supplyToPool3() public {
        test_CreatePool();
       
erc20Contract.mint(sam, 100000);
        vm.prank(sam);

        

        erc20Contract.approve(address(poolAdd), 100000);
        vm.prank(sam);

        FundingPool(address(poolAdd)).supplyToPool(
            poolId,
            address(erc20Contract),
            100000,
            uint32(maxLoanDuration),
            apr,
            block.timestamp + 3600
        );
}
}
