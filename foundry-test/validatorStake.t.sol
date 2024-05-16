// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/console.sol";
import "contracts/utils/LibShare.sol";
import "contracts/utils/sampleERC20.sol";
import "contracts/validatorStake.sol";

contract validatorStakeTest is Test {



    validatorStake validatorStakeContract ;
    SampleERC20 sampleERC20;

    event Staked(address validator, uint256 amount);
    event NewStake(address validator, uint256 amount, uint256 TotalStakedAmount);
    event RefundedStake(address validator, uint256 refundedAmount, uint256 LeftStakedAmount);



    address payable alice = payable(address(0xABCD));
    address payable bob = payable(address(0xABCC));
    address payable validator = payable(address(0xABCD));


    function testDeployandInitialize() public {
        vm.prank(alice);
        sampleERC20 = new SampleERC20();
        address implementation = address(new validatorStake());

        address proxy = address(new ERC1967Proxy(implementation, ""));
        
          validatorStakeContract = validatorStake(proxy);
          validatorStakeContract.initialize();
               
         validatorStakeContract.transferOwnership(alice);

         assertEq(validatorStakeContract.owner(),alice, "not the owner");

    }


    function test_PauseAndUnpause() public {
        testDeployandInitialize();
        // Assert owner is Alice
        assertEq(validatorStakeContract.owner(), alice, "Invalid contract owner");
        vm.prank(alice);
        validatorStakeContract.pause();
        assertTrue(validatorStakeContract.paused(), "Failed to pause contract");
        vm.prank(alice);
        validatorStakeContract.unpause();
        assertFalse(validatorStakeContract.paused(), "Failed to unpause contract");
    }


function test_Pause_by_nonOwner() public {
    //  it should mot be paused by non-owner 

     test_PauseAndUnpause();
     vm.prank(bob);
         vm.expectRevert(bytes("Ownable: caller is not the owner"));
     validatorStakeContract.pause();



    }

    function test_Unpause_by_non_owner() public {
    //  it should mot be Unpaused by non-owner 

test_Pause_by_nonOwner();
     vm.prank(bob);
         vm.expectRevert(bytes("Ownable: caller is not the owner"));
     validatorStakeContract.unpause();



    }

    function test_Stake() public {
        // should let validator add fund 
        test_Unpause_by_non_owner();
                vm.startPrank(bob);


        sampleERC20.mint(bob, 100000000000000000000);
             sampleERC20.approve(address(validatorStakeContract), 100000000000000000000);
            validatorStakeContract.Stake(100000000000000000000,  address(sampleERC20));
            uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
                assertEq(bal, 100000000000000000000, "Invalid ERC20 balance");


            // string stakeDetail = ValidatorStake.validatorStakes(bob);
            //     expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
            //     expect(stakeDetail.refundedAmount).to.equal("0");
 // Check if the event is emitted correctly
        // vm.expectEmit(true, true, true, true);
        // emit Staked(address(1), 100000000000000000000);
            vm.stopPrank();


    }

function testRevertZeroAddress() public {
    // should reject staking of zero address 
        test_Stake();

        vm.startPrank(bob);
        vm.expectRevert("zero Address");
        validatorStakeContract.Stake(100000000000000000000, address(0));
        vm.stopPrank();

    }

    function testRevertLowAmount() public {
        // should reject staking of zero amount
        testRevertZeroAddress();

        vm.startPrank(bob);
        vm.expectRevert("Low Amount");
        validatorStakeContract.Stake(0, address(sampleERC20));
        vm.stopPrank();

    }

    function testRevertWhenPaused() public {
        // should prevent staking when paused 
        testRevertLowAmount();
        vm.prank(alice);
        validatorStakeContract.pause();

        vm.startPrank(bob);
        vm.expectRevert("Pausable: paused");
        validatorStakeContract.Stake(1100000000000000000000, address(sampleERC20));
        vm.stopPrank();
    }
    function test_AddStake() public {
        // should let validator add more fund
        testRevertWhenPaused();


vm.prank(alice);
        validatorStakeContract.unpause();

        vm.startPrank(bob);
        sampleERC20.mint(bob, 100000000000000000000);
        sampleERC20.approve(address(validatorStakeContract), 100000000000000000000);
            validatorStakeContract.addStake(100000000000000000000,  address(sampleERC20));
           uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
                assertEq(bal, 200000000000000000000, "Invalid ERC20 balance");
                            vm.stopPrank();


    }

function testRevert_AddStakeZeroAddress() public {
    // should reject adding stake of zero address 
        test_AddStake();

        vm.startPrank(bob);
        vm.expectRevert("zero Address");
        validatorStakeContract.Stake(100000000000000000000, address(0));

        vm.stopPrank();
    }

    function test_AddStake_RevertLowAmount() public {
        // should reject adding stake of zero amount
        testRevert_AddStakeZeroAddress();

        vm.startPrank(bob);
        vm.expectRevert("Low Amount");
        validatorStakeContract.Stake(0, address(sampleERC20));
        vm.stopPrank();

    }

    function test_addStake_RevertWhenPaused() public {
        // should prevent adding stake when paused 
        test_AddStake_RevertLowAmount();
        vm.prank(alice);
        validatorStakeContract.pause();

        vm.startPrank(bob);
        vm.expectRevert("Pausable: paused");
        validatorStakeContract.addStake(1100000000000000000000, address(sampleERC20));
        vm.stopPrank();



          vm.prank(alice);
        validatorStakeContract.unpause();
    }
function test_multipleStakes() public {
// should handle multiple stakes and keep correct total
test_addStake_RevertWhenPaused();

        vm.startPrank(bob);
sampleERC20.mint(bob, 100000000000000000000);
             sampleERC20.approve(address(validatorStakeContract), 100000000000000000000);
            validatorStakeContract.Stake(50000000000000000000, address(sampleERC20));
            validatorStakeContract.addStake(50000000000000000000, address(sampleERC20));
            // details memory details =  validatorStakeContract.validatorStakes(bob);
            // assertEq((details.stakedAmount),100000000000000000000);

            uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
            assertEq(bal, 300000000000000000000, "Invalid contract balance");

        vm.stopPrank();


}

function test_Refund_whenPaused() public {
    test_multipleStakes();
    // should not allow the owner to refund stakes when paused
     vm.prank(alice);
     validatorStakeContract.pause();

     vm.startPrank(alice);
        vm.expectRevert("Pausable: paused");
        validatorStakeContract.RefundStake(bob, address(sampleERC20), 300000000000000000000);
         uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
            assertEq(bal, 300000000000000000000, "Invalid contract balance");
            validatorStakeContract.unpause();


                vm.stopPrank();





}

function test_Refund_withLow_Amount() public {
    // should not allow refund with low amount
    test_Refund_whenPaused();

     vm.startPrank(alice);
        vm.expectRevert("Low Amount");
        validatorStakeContract.RefundStake(bob, address(sampleERC20), 0);
         uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
            assertEq(bal, 300000000000000000000, "Invalid contract balance");


                vm.stopPrank();




}

function test_Refund_withLow_0_erc20Address() public {
    // it should not refund with 0 erc20 address 
    test_Refund_withLow_Amount();

 vm.startPrank(alice);
vm.expectRevert("zero Address");
        validatorStakeContract.RefundStake(bob, address(0), 300000000000000000000);
         uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
            assertEq(bal, 300000000000000000000, "Invalid contract balance");


                vm.stopPrank();

}
 function test_Refund_withLow_0_ValidatorAddress() public {
    // it should not allow refund with zero validator address 
    test_Refund_withLow_0_erc20Address();

    vm.startPrank(alice);
    vm.expectRevert("zero Address");
        validatorStakeContract.RefundStake(address(0),  address(sampleERC20), 300000000000000000000);
         uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
         assertEq(bal,300000000000000000000, "incorrect balance");


                vm.stopPrank();

 }

function test_Refund_by_nonOwner() public {

// it should not refund staked amount by non-owner 
test_Refund_withLow_0_ValidatorAddress();
 vm.startPrank(bob);

     vm.expectRevert(bytes("Ownable: caller is not the owner"));
    validatorStakeContract.RefundStake(bob, address(sampleERC20), 300000000000000000000);
                    vm.stopPrank();



}

function test_OwnerCanRefundStakes() public {
test_Refund_by_nonOwner();    

//   should allow the owner to refund stakes
    vm.prank(alice);
    validatorStakeContract.RefundStake(bob, address(sampleERC20), 300000000000000000000);

            // assertEq(sampleERC20.balanceOf(validator), 300 ether - stakedAmount + refundAmount);

    
    // vm.expectEmit(true, true, true, false);

    // emit RefundedStake(bob, 300000000000000000000,100000000000000000000 );

    // Check the final balance of the validatorStake in sampleERC20
    uint256 bal = sampleERC20.balanceOf(address(validatorStakeContract));
    assertEq(bal, 0,"Incorrect balance");
}

 function test_NewStake() public {
        // should let validator add fund again
test_OwnerCanRefundStakes();
vm.startPrank(bob);


        sampleERC20.mint(bob, 100000000000000000000);
             sampleERC20.approve(address(validatorStakeContract), 100000000000000000000);
            validatorStakeContract.Stake(100000000000000000000,  address(sampleERC20));
            uint256 bal =  sampleERC20.balanceOf(address(validatorStakeContract));
                assertEq(bal, 100000000000000000000, "Invalid ERC20 balance");


           
            vm.stopPrank();


    }

function test_OwnerCanRefund_multiple_Stakes() public {
    test_NewStake();

//   should allow the owner to refund multiples stakes
                vm.startPrank(alice);
    validatorStakeContract.RefundStake(bob, address(sampleERC20), 50000000000000000000);
    validatorStakeContract.RefundStake(bob, address(sampleERC20), 50000000000000000000);


    uint256 bal = sampleERC20.balanceOf(address(validatorStakeContract));
    assertEq(bal, 0,"Incorrect balance");
                vm.stopPrank();

}
}