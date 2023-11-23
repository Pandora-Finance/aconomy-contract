// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/poolRegistry.sol";
import "contracts/AconomyFee.sol";
import "contracts/poolAddress.sol";

import "contracts/AttestationServices.sol";
import "contracts/Libraries/LibPool.sol";
import "contracts/utils/sampleERC20.sol";


contract poolRegistryTest is Test {
        AconomyFee aconomyFee;
        SampleERC20 sampleERC20;
        AttestationRegistry attestRegistry;
        AttestationServices attestServices;
        FundingPool fundingPool;
        poolRegistry poolRegis;
        poolAddress poolAddressInstance;



    uint32 public paymentCycleDuration = 30 days;
    uint32 public expiration = 2 days;
    uint32 public loanDuration = 150 days;
    uint32 public loanDefaultDuration = 90 days;
    uint32 public loanExpirationDuration = 180 days;
    // uint256 public poolId1;
    // uint256 public poolId2;
    // uint256 public loanId1;
    // uint256 public newpoolId;




          address payable alice = payable(address(0xABCD));
    address payable account0 = payable(address(0xABEE));
    address payable random = payable(address(0xABCC));

    function testDeployandInitialize() public {
        vm.startPrank(account0);
        sampleERC20 = new SampleERC20();   
        aconomyFee = new AconomyFee();
        attestRegistry= new AttestationRegistry();
        attestServices= new AttestationServices(attestRegistry);

        fundingPool = new FundingPool();
        // fundingPool.initialize(address(factory),alice,"Aconomy","ACO");
         address implementation = address(new poolRegistry());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        poolRegis = poolRegistry(proxy);
          poolRegis.initialize(attestServices,address(aconomyFee),address(fundingPool));
        poolRegis.transferOwnership(account0);


        address implementation1= address(new poolAddress());
        address proxy1= address(new ERC1967Proxy(implementation1, ""));
        poolAddressInstance = poolAddress(proxy1);
        poolAddressInstance.initialize(address(poolRegis),address(aconomyFee));
        poolAddressInstance.transferOwnership(account0);

        fundingPool.initialize(account0,address(poolRegis));


vm.stopPrank();

    }  
    function test_owner() public {
        testDeployandInitialize();
        assertEq(poolRegis.owner(),account0,"not the owner");
        assertEq(poolAddressInstance.owner(),account0,"not  owner");

        assertEq(fundingPool.poolOwner(),account0,"not  owner");

        
    }
    function test_SetAconomyFee() public {
        test_owner();
    // should set Aconomyfee

    // Set AconomyPoolFee to 200
    vm.startPrank(account0);
    aconomyFee.setAconomyPoolFee(200);

    uint256 protocolFee = aconomyFee.AconomyPoolFee();
    assertEq(protocolFee, 200, "AconomyPoolFee should be set to 200");

    // Verify the AconomyFee owner address
    address aconomyFeeOwner = aconomyFee.getAconomyOwnerAddress();
    assertEq(aconomyFeeOwner, account0, "AconomyFee owner should be account0");
    vm.stopPrank();
}
function test_PauseUnpauseNonOwner() public {
    // should not let non owner to pause and unpause the contract
    test_SetAconomyFee();

    // Attempt to pause the contract by a non-owner
        vm.startPrank(random);

    vm.expectRevert(bytes("Ownable: caller is not the owner"));
        poolRegis.pause();
        vm.stopPrank();


    // Pause the contract by owner
    vm.prank(account0);
    poolRegis.pause();


    // Attempt to unpause the contract by a non-owner
            vm.startPrank(random);

            vm.expectRevert(bytes("Ownable: caller is not the owner"));
                poolRegis.unpause();
            vm.stopPrank();



    // Unpause the contract by owner
        vm.prank(account0);
        poolRegis.unpause();
}
function test_create_attestRegistry()  public {
// should create attestRegistry 
test_PauseUnpauseNonOwner();
        assert(address(attestServices) != address(0));
}
function test_CreatePool() public {
    // should create Pool
     test_create_attestRegistry();
     vm.startPrank(account0);

    // Create a new pool
  uint256 poolId = poolRegis.createPool(
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        1000,
        "adya.com",
        true,
        true
    );
assertEq(poolId,1,"invalid poolId");
    // Get the pool address
    // address pool1Address = poolRegis.getPoolAddress(poolId1);

    // Perform lender verification
   (bool isVerified ,) = poolRegis.lenderVerification(poolId, account0);
    assertTrue(isVerified, "Lender verification failed");

    // Perform borrower verification
    (bool isVerified_ ,) = poolRegis.borrowerVerification(poolId, account0);
    assertTrue(isVerified_, "Borrower verification failed");
}

}