# Solidity API

## AconomyFee

### _AconomyPoolFee

```solidity
uint16 _AconomyPoolFee
```

### _AconomyPiMarketFee

```solidity
uint16 _AconomyPiMarketFee
```

### _AconomyNFTLendBorrowFee

```solidity
uint16 _AconomyNFTLendBorrowFee
```

### SetAconomyPoolFee

```solidity
event SetAconomyPoolFee(uint16 newFee, uint16 oldFee)
```

### SetAconomyPiMarketFee

```solidity
event SetAconomyPiMarketFee(uint16 newFee, uint16 oldFee)
```

### SetAconomyNFTLendBorrowFee

```solidity
event SetAconomyNFTLendBorrowFee(uint16 newFee, uint16 oldFee)
```

### AconomyPoolFee

```solidity
function AconomyPoolFee() public view returns (uint16)
```

### AconomyPiMarketFee

```solidity
function AconomyPiMarketFee() public view returns (uint16)
```

### AconomyNFTLendBorrowFee

```solidity
function AconomyNFTLendBorrowFee() public view returns (uint16)
```

### getAconomyOwnerAddress

```solidity
function getAconomyOwnerAddress() public view returns (address)
```

### setAconomyPoolFee

```solidity
function setAconomyPoolFee(uint16 newFee) public
```

Sets the protocol fee.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newFee | uint16 | The value of the new fee percentage in bps. |

### setAconomyPiMarketFee

```solidity
function setAconomyPiMarketFee(uint16 newFee) public
```

### setAconomyNFTLendBorrowFee

```solidity
function setAconomyNFTLendBorrowFee(uint16 newFee) public
```

## AttestationRegistry

### _registry

```solidity
mapping(bytes32 => struct IAttestationRegistry.ASRecord) _registry
```

### Registered

```solidity
event Registered(bytes32 uuid, uint256 index, bytes schema, address attester)
```

### register

```solidity
function register(bytes schema) external returns (bytes32)
```

_Submits and reserve a new AS_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| schema | bytes | The AS data schema. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The UUID of the new AS. |

### getAS

```solidity
function getAS(bytes32 uuid) external view returns (struct IAttestationRegistry.ASRecord)
```

_Returns an existing AS by UUID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| uuid | bytes32 | The UUID of the AS to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IAttestationRegistry.ASRecord | The AS data members. |

## AttestationServices

### AttestationRegistryAddress

```solidity
address AttestationRegistryAddress
```

### constructor

```solidity
constructor(contract IAttestationRegistry registry) public
```

### Attestation

```solidity
struct Attestation {
  bytes32 uuid;
  bytes32 schema;
  address recipient;
  address attester;
  uint256 time;
  uint256 revocationTime;
  bytes data;
}
```

### Attested

```solidity
event Attested(address recipient, address attester, bytes32 uuid, bytes32 schema)
```

Triggered when an attestation has been made.
     ~recipient The recipient of the attestation.
     ~attester The attesting account.
     ~uuid The UUID the revoked attestation.
     ~schema The UUID of the AS.

### Revoked

```solidity
event Revoked(address recipient, address attester, bytes32 uuid, bytes32 schema)
```

### getASRegistry

```solidity
function getASRegistry() external view returns (contract IAttestationRegistry)
```

### attest

```solidity
function attest(address recipient, bytes32 schema, bytes data) public virtual returns (bytes32)
```

_Attests to a specific AS._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| recipient | address | The recipient of the attestation. |
| schema | bytes32 | The UUID of the AS. |
| data | bytes |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The UUID of the new attestation. |

### revoke

```solidity
function revoke(bytes32 uuid) public virtual
```

_Revokes an existing attestation to a specific AS._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| uuid | bytes32 | The UUID of the attestation to revoke. |

### isAddressActive

```solidity
function isAddressActive(bytes32 uuid) public view returns (bool)
```

_Checks whether an attestation is active._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| uuid | bytes32 | The UUID of the attestation to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Whether an attestation is active. |

### isAddressValid

```solidity
function isAddressValid(bytes32 uuid) public view returns (bool)
```

_Checks whether an attestation exists._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| uuid | bytes32 | The UUID of the attestation to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | Whether an attestation exists. |

## FundingPool

### poolOwner

```solidity
address poolOwner
```

### poolRegistryAddress

```solidity
address poolRegistryAddress
```

### initialize

```solidity
function initialize(address _poolOwner, address _poolRegistry) external
```

Initializer function.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolOwner | address | The pool owner's address. |
| _poolRegistry | address | The address of the poolRegistry contract. |

### bidId

```solidity
uint256 bidId
```

### BidRepaid

```solidity
event BidRepaid(uint256 bidId, uint256 PaidAmount)
```

### BidRepayment

```solidity
event BidRepayment(uint256 bidId, uint256 PaidAmount)
```

### BidAccepted

```solidity
event BidAccepted(address lender, address reciever, uint256 BidId, uint256 PoolId, uint256 Amount, uint256 paymentCycleAmount)
```

### BidRejected

```solidity
event BidRejected(address lender, uint256 BidId, uint256 PoolId, uint256 Amount)
```

### Withdrawn

```solidity
event Withdrawn(address reciever, uint256 BidId, uint256 PoolId, uint256 Amount)
```

### SuppliedToPool

```solidity
event SuppliedToPool(uint256 poolId, uint256 BidId, address ERC20Token, uint256 tokenAmount, uint16 APR, uint256 Duration, uint256 Expiration)
```

### InstallmentRepaid

```solidity
event InstallmentRepaid(uint256 poolId, uint256 bidId, uint256 owedAmount, uint256 dueAmount, uint256 interest)
```

### FullAmountRepaid

```solidity
event FullAmountRepaid(uint256 poolId, uint256 bidId, uint256 Amount, uint256 interest)
```

### Installments

```solidity
struct Installments {
  uint256 monthlyCycleInterest;
  uint32 installments;
  uint32 installmentsPaid;
  uint32 defaultDuration;
  uint16 protocolFee;
}
```

### FundDetail

```solidity
struct FundDetail {
  uint256 amount;
  uint256 expiration;
  uint32 maxDuration;
  uint16 interestRate;
  enum FundingPool.BidState state;
  uint32 bidTimestamp;
  uint32 acceptBidTimestamp;
  uint256 paymentCycleAmount;
  uint256 totalRepaidPrincipal;
  uint32 lastRepaidTimestamp;
  struct FundingPool.Installments installment;
  struct FundingPool.RePayment Repaid;
}
```

### RePayment

```solidity
struct RePayment {
  uint256 amount;
  uint256 interest;
}
```

### BidState

```solidity
enum BidState {
  PENDING,
  ACCEPTED,
  PAID,
  WITHDRAWN,
  REJECTED
}
```

### lenderPoolFundDetails

```solidity
mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => struct FundingPool.FundDetail)))) lenderPoolFundDetails
```

### supplyToPool

```solidity
function supplyToPool(uint256 _poolId, address _ERC20Address, uint256 _amount, uint32 _maxLoanDuration, uint256 _expiration, uint16 _APR) external
```

Allows a lender to supply funds to the pool owner.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the funds being supplied. |
| _amount | uint256 | The amount of funds being supplied. |
| _maxLoanDuration | uint32 | The duration of the loan after being accepted. |
| _expiration | uint256 | The time stamp within which the loan has to be accepted. |
| _APR | uint16 | The annual interest in bps |

### AcceptBid

```solidity
function AcceptBid(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender, address _receiver) external
```

Accepts the specified bid to supply to the pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the bid funds being accepted. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The address of the lender. |
| _receiver | address | The address of the funds receiver. |

### RejectBid

```solidity
function RejectBid(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) external
```

Rejects the bid to supply to the pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the funds contract. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The address of the lender. |

### isBidExpired

```solidity
function isBidExpired(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) public view returns (bool)
```

Checks if bid has expired.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the funds contract. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The address of the lender. |

### isLoanDefaulted

```solidity
function isLoanDefaulted(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) public view returns (bool)
```

Checks if loan is defaulted.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the funds contract. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The address of the lender. |

### isPaymentLate

```solidity
function isPaymentLate(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) public view returns (bool)
```

Checks if loan repayment is late.

_Returned value is type boolean._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean of late payment. |

### calculateNextDueDate

```solidity
function calculateNextDueDate(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) public view returns (uint256 dueDate_)
```

Calculates and returns the next due date.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| dueDate_ | uint256 | unix time of due date in uint256. |

### viewInstallmentAmount

```solidity
function viewInstallmentAmount(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) external view returns (uint256)
```

Returns the installment amount to be paid at the called timestamp.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | installment amount in uint256. |

### repayMonthlyInstallment

```solidity
function repayMonthlyInstallment(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) external
```

Repays the monthly installment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

### viewFullRepayAmount

```solidity
function viewFullRepayAmount(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) public view returns (uint256)
```

Returns the full amount to be repaid.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Full amount to be paid in uint256. |

### RepayFullAmount

```solidity
function RepayFullAmount(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) external
```

Repays the full amount for the loan.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

### _repayBid

```solidity
function _repayBid(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender, uint256 _amount, uint256 _interest, uint256 _owedAmount) internal
```

Repays the specified amount for the loan.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |
| _amount | uint256 | The amount being repaid. |
| _interest | uint256 | The interest being repaid. |
| _owedAmount | uint256 | The total owed amount at the called timestamp. |

### Withdraw

```solidity
function Withdraw(uint256 _poolId, address _ERC20Address, uint256 _bidId, address _lender) external
```

Allows the lender to withdraw the loan bid if it is still pending.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _ERC20Address | address | The address of the erc20 funds. |
| _bidId | uint256 | The Id of the bid. |
| _lender | address | The lender address. |

## BokkyPooBahsDateTimeLibrary

### SECONDS_PER_DAY

```solidity
uint256 SECONDS_PER_DAY
```

### SECONDS_PER_HOUR

```solidity
uint256 SECONDS_PER_HOUR
```

### SECONDS_PER_MINUTE

```solidity
uint256 SECONDS_PER_MINUTE
```

### OFFSET19700101

```solidity
int256 OFFSET19700101
```

### DOW_MON

```solidity
uint256 DOW_MON
```

### DOW_TUE

```solidity
uint256 DOW_TUE
```

### DOW_WED

```solidity
uint256 DOW_WED
```

### DOW_THU

```solidity
uint256 DOW_THU
```

### DOW_FRI

```solidity
uint256 DOW_FRI
```

### DOW_SAT

```solidity
uint256 DOW_SAT
```

### DOW_SUN

```solidity
uint256 DOW_SUN
```

### _daysFromDate

```solidity
function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days)
```

### _daysToDate

```solidity
function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day)
```

### timestampFromDate

```solidity
function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp)
```

### timestampFromDateTime

```solidity
function timestampFromDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (uint256 timestamp)
```

### timestampToDate

```solidity
function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day)
```

### timestampToDateTime

```solidity
function timestampToDateTime(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
```

### isValidDate

```solidity
function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid)
```

### isValidDateTime

```solidity
function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) internal pure returns (bool valid)
```

### isLeapYear

```solidity
function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear)
```

### _isLeapYear

```solidity
function _isLeapYear(uint256 year) internal pure returns (bool leapYear)
```

### isWeekDay

```solidity
function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay)
```

### isWeekEnd

```solidity
function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd)
```

### getDaysInMonth

```solidity
function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth)
```

### _getDaysInMonth

```solidity
function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth)
```

### getDayOfWeek

```solidity
function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek)
```

### getYear

```solidity
function getYear(uint256 timestamp) internal pure returns (uint256 year)
```

### getMonth

```solidity
function getMonth(uint256 timestamp) internal pure returns (uint256 month)
```

### getDay

```solidity
function getDay(uint256 timestamp) internal pure returns (uint256 day)
```

### getHour

```solidity
function getHour(uint256 timestamp) internal pure returns (uint256 hour)
```

### getMinute

```solidity
function getMinute(uint256 timestamp) internal pure returns (uint256 minute)
```

### getSecond

```solidity
function getSecond(uint256 timestamp) internal pure returns (uint256 second)
```

### addYears

```solidity
function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp)
```

### addMonths

```solidity
function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp)
```

### addDays

```solidity
function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp)
```

### addHours

```solidity
function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp)
```

### addMinutes

```solidity
function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp)
```

### addSeconds

```solidity
function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp)
```

### subYears

```solidity
function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp)
```

### subMonths

```solidity
function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp)
```

### subDays

```solidity
function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp)
```

### subHours

```solidity
function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp)
```

### subMinutes

```solidity
function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp)
```

### subSeconds

```solidity
function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp)
```

### diffYears

```solidity
function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years)
```

### diffMonths

```solidity
function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months)
```

### diffDays

```solidity
function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days)
```

### diffHours

```solidity
function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours)
```

### diffMinutes

```solidity
function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes)
```

### diffSeconds

```solidity
function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds)
```

## LibCalculations

### WAD

```solidity
uint256 WAD
```

### percentFactor

```solidity
function percentFactor(uint256 decimals) internal pure returns (uint256)
```

### percent

```solidity
function percent(uint256 self, uint16 percentage) public pure returns (uint256)
```

Returns a percentage value of a number.
     self The number to get a percentage of.
     percentage The percentage value to calculate with 2 decimal places (10000 = 100%).

### percent

```solidity
function percent(uint256 self, uint256 percentage, uint256 decimals) internal pure returns (uint256)
```

Returns a percentage value of a number.
     self The number to get a percentage of.
     percentage The percentage value to calculate with.
     decimals The number of decimals the percentage value is in.

### payment

```solidity
function payment(uint256 principal, uint32 loanDuration, uint32 cycleDuration, uint16 apr) public pure returns (uint256)
```

### lastRepaidTimestamp

```solidity
function lastRepaidTimestamp(struct poolStorage.Loan _loan) internal view returns (uint32)
```

### calculateInstallmentAmount

```solidity
function calculateInstallmentAmount(uint256 amount, uint256 leftAmount, uint16 interestRate, uint256 paymentCycleAmount, uint256 paymentCycle, uint32 _lastRepaidTimestamp, uint256 timestamp, uint256 acceptBidTimestamp, uint256 maxDuration) internal pure returns (uint256 owedPrincipal_, uint256 duePrincipal_, uint256 interest_)
```

### owedAmount

```solidity
function owedAmount(struct poolStorage.Loan _loan, uint256 _timestamp) internal view returns (uint256 owedPrincipal_, uint256 duePrincipal_, uint256 interest_)
```

### calculateOwedAmount

```solidity
function calculateOwedAmount(uint256 principal, uint256 totalRepaidPrincipal, uint16 _interestRate, uint256 _paymentCycleAmount, uint256 _paymentCycle, uint256 _lastRepaidTimestamp, uint256 _timestamp, uint256 _startTimestamp, uint256 _loanDuration) internal pure returns (uint256 owedPrincipal_, uint256 duePrincipal_, uint256 interest_)
```

### calculateInterest

```solidity
function calculateInterest(uint256 _owedPrincipal, uint16 _interestRate, uint256 _owedTime) internal pure returns (uint256 _interest)
```

## LibNFTLendingBorrowing

### acceptBid

```solidity
function acceptBid(struct NFTlendingBorrowing.NFTdetail nftDetail, struct NFTlendingBorrowing.BidDetail bidDetail, uint256 amountToAconomy, address aconomyOwner) external
```

### RejectBid

```solidity
function RejectBid(struct NFTlendingBorrowing.NFTdetail nftDetail, struct NFTlendingBorrowing.BidDetail bidDetail) external
```

## LibPool

### deployPoolAddress

```solidity
function deployPoolAddress(address _poolOwner, address _poolRegistry, address _FundingPool) external returns (address)
```

Returns the address of the deployed pool contract.

_Returned value is type address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolOwner | address | The address set to own the pool. |
| _poolRegistry | address | The address of the poolRegistry contract. |
| _FundingPool | address | the address of the proxy implementation of FundingPool. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address of the deployed . |

## LibPoolAddress

### acceptLoan

```solidity
function acceptLoan(struct poolStorage.Loan loan, address poolRegistryAddress, address AconomyFeeAddress) external returns (uint256 amountToAconomy, uint256 amountToPool, uint256 amountToBorrower)
```

## WadRayMath

Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)

### WAD

```solidity
uint256 WAD
```

### halfWAD

```solidity
uint256 halfWAD
```

### wad

```solidity
function wad() internal pure returns (uint256)
```

### pctToWad

```solidity
function pctToWad(uint16 a) internal pure returns (uint256)
```

### halfWad

```solidity
function halfWad() internal pure returns (uint256)
```

### wadMul

```solidity
function wadMul(uint256 a, uint256 b) internal pure returns (uint256)
```

### wadDiv

```solidity
function wadDiv(uint256 a, uint256 b) internal pure returns (uint256)
```

### wadPow

```solidity
function wadPow(uint256 x, uint256 n) internal pure returns (uint256)
```

### _pow

```solidity
function _pow(uint256 x, uint256 n, uint256 p, function (uint256,uint256) pure returns (uint256) mul) internal pure returns (uint256 z)
```

## NFTlendingBorrowing

### NFTid

```solidity
uint256 NFTid
```

### AconomyFeeAddress

```solidity
address AconomyFeeAddress
```

### NFTdetail

```solidity
struct NFTdetail {
  uint256 NFTtokenId;
  address tokenIdOwner;
  address contractAddress;
  uint32 duration;
  uint256 expiration;
  uint256 expectedAmount;
  uint16 percent;
  bool listed;
  bool bidAccepted;
  bool repaid;
}
```

### BidDetail

```solidity
struct BidDetail {
  uint256 bidId;
  uint16 percent;
  uint32 duration;
  uint256 expiration;
  address bidderAddress;
  address ERC20Address;
  uint256 Amount;
  uint256 acceptedTimestamp;
  uint16 protocolFee;
  bool withdrawn;
  bool bidAccepted;
}
```

### NFTdetails

```solidity
mapping(uint256 => struct NFTlendingBorrowing.NFTdetail) NFTdetails
```

### Bids

```solidity
mapping(uint256 => struct NFTlendingBorrowing.BidDetail[]) Bids
```

### AppliedBid

```solidity
event AppliedBid(uint256 BidId, uint256 NFTid, uint256 TokenId, address ContractAddress, uint256 BidAmount, uint16 APY, uint32 Duration, uint256 Expiration, address ERC20Address)
```

### PercentSet

```solidity
event PercentSet(uint256 NFTid, uint16 Percent)
```

### DurationSet

```solidity
event DurationSet(uint256 NFTid, uint32 Duration)
```

### ExpectedAmountSet

```solidity
event ExpectedAmountSet(uint256 NFTid, uint256 expectedAmount)
```

### NFTlisted

```solidity
event NFTlisted(uint256 NFTid, uint256 TokenId, address ContractAddress, uint256 ExpectedAmount, uint16 Percent, uint32 Duration, uint256 Expiration)
```

### repaid

```solidity
event repaid(uint256 NFTid, uint256 BidId, uint256 Amount, address ContractAddress)
```

### Withdrawn

```solidity
event Withdrawn(uint256 NFTid, uint256 BidId, uint256 Amount)
```

### NFTRemoved

```solidity
event NFTRemoved(uint256 NFTId, address ContractAddress)
```

### BidRejected

```solidity
event BidRejected(uint256 NFTid, uint256 BidId, address recieverAddress, uint256 Amount, address ContractAddress)
```

### AcceptedBid

```solidity
event AcceptedBid(uint256 NFTid, uint256 BidId, uint256 Amount, uint256 ProtocolAmount, address ContractAddress)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _aconomyFee) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### onlyOwnerOfToken

```solidity
modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId)
```

### NFTOwner

```solidity
modifier NFTOwner(uint256 _NFTid)
```

### listNFTforBorrowing

```solidity
function listNFTforBorrowing(uint256 _tokenId, address _contractAddress, uint16 _percent, uint32 _duration, uint256 _expiration, uint256 _expectedAmount) external returns (uint256 _NFTid)
```

Lists the nft for borrowing.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |
| _contractAddress | address | The address of the token contract. |
| _percent | uint16 | The interest percentage expected. |
| _duration | uint32 | The duration of the loan. |
| _expiration | uint256 | The expiration duration of the loan for the NFT. |
| _expectedAmount | uint256 | The loan amount expected. |

### setPercent

```solidity
function setPercent(uint256 _NFTid, uint16 _percent) public
```

Sets the expected percentage.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _percent | uint16 | The interest percentage expected. |

### setDurationTime

```solidity
function setDurationTime(uint256 _NFTid, uint32 _duration) public
```

Sets the expected duration.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _duration | uint32 | The duration expected. |

### setExpectedAmount

```solidity
function setExpectedAmount(uint256 _NFTid, uint256 _expectedAmount) public
```

Sets the expected loan amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _expectedAmount | uint256 | The expected amount. |

### Bid

```solidity
function Bid(uint256 _NFTid, uint256 _bidAmount, address _ERC20Address, uint16 _percent, uint32 _duration, uint256 _expiration) external
```

Allows a user to bid a loan for an nft.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail. |
| _bidAmount | uint256 | The amount being bidded. |
| _ERC20Address | address | The address of the tokens being bidded. |
| _percent | uint16 | The interest percentage for the loan bid. |
| _duration | uint32 | The duration of the loan bid. |
| _expiration | uint256 | The timestamp after which the bid can be withdrawn. |

### AcceptBid

```solidity
function AcceptBid(uint256 _NFTid, uint256 _bidId) external
```

Accepts the specified bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _bidId | uint256 | The Id of the bid. |

### rejectBid

```solidity
function rejectBid(uint256 _NFTid, uint256 _bidId) external
```

Rejects the specified bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _bidId | uint256 | The Id of the bid. |

### viewRepayAmount

```solidity
function viewRepayAmount(uint256 _NFTid, uint256 _bidId) external view returns (uint256)
```

### Repay

```solidity
function Repay(uint256 _NFTid, uint256 _bidId) external
```

Repays the loan amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _bidId | uint256 | The Id of the bid. |

### withdraw

```solidity
function withdraw(uint256 _NFTid, uint256 _bidId) external
```

Withdraws the bid amount after expiration.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |
| _bidId | uint256 | The Id of the bid. |

### removeNFTfromList

```solidity
function removeNFTfromList(uint256 _NFTid) external
```

Removes the nft from listing.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NFTid | uint256 | The Id of the NFTDetail |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## IAttestationRegistry

### ASRecord

```solidity
struct ASRecord {
  bytes32 uuid;
  uint256 index;
  bytes schema;
}
```

### register

```solidity
function register(bytes schema) external returns (bytes32)
```

_Submits and reserve a new AS_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| schema | bytes | The AS data schema. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The UUID of the new AS. |

### getAS

```solidity
function getAS(bytes32 uuid) external view returns (struct IAttestationRegistry.ASRecord)
```

_Returns an existing AS by UUID_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| uuid | bytes32 | The UUID of the AS to retrieve. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct IAttestationRegistry.ASRecord | The AS data members. |

## IAttestationServices

### register

```solidity
function register(bytes schema) external returns (bytes32)
```

## poolAddress

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _poolRegistry, address _AconomyFeeAddress) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### loanAccepted

```solidity
event loanAccepted(uint256 poolId, uint256 loanId, address lender)
```

### repaidAmounts

```solidity
event repaidAmounts(uint256 poolId, uint256 owedPrincipal, uint256 duePrincipal, uint256 interest)
```

### AcceptedLoanDetail

```solidity
event AcceptedLoanDetail(uint256 poolId, uint256 loanId, uint256 amountToAconomy, uint256 amountToPool, uint256 amountToBorrower)
```

### LoanRepaid

```solidity
event LoanRepaid(uint256 poolId, uint256 loanId, uint256 Amount)
```

### LoanRepayment

```solidity
event LoanRepayment(uint256 poolId, uint256 loanId, uint256 Amount)
```

### SubmittedLoan

```solidity
event SubmittedLoan(uint256 poolId, uint256 loanId, address borrower, address receiver, uint256 paymentCycleAmount)
```

### loanRequest

```solidity
function loanRequest(address _lendingToken, uint256 _poolId, uint256 _principal, uint32 _duration, uint32 _expirationDuration, uint16 _APR, address _receiver) public returns (uint256 loanId_)
```

Lets a borrower request for a loan.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _lendingToken | address | The address of the token being requested. |
| _poolId | uint256 | The Id of the pool. |
| _principal | uint256 | The principal amount being requested. |
| _duration | uint32 | The duration of the loan. |
| _expirationDuration | uint32 | The time in which the loan has to be accepted before it expires. |
| _APR | uint16 | The annual interest percentage in bps. |
| _receiver | address | The receiver of the funds. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| loanId_ | uint256 | Id of the loan. |

### AcceptLoan

```solidity
function AcceptLoan(uint256 _loanId) external returns (uint256 amountToAconomy, uint256 amountToPool, uint256 amountToBorrower)
```

Accepts the loan request.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

### isLoanExpired

```solidity
function isLoanExpired(uint256 _loanId) public view returns (bool)
```

Checks if the loan has expired.

_Return type is of boolean._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean indicating if the loan is expired. |

### isLoanDefaulted

```solidity
function isLoanDefaulted(uint256 _loanId) public view returns (bool)
```

Checks if the loan has defaulted.

_Return type is of boolean._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean indicating if the loan is defaulted. |

### lastRepaidTimestamp

```solidity
function lastRepaidTimestamp(uint256 _loanId) public view returns (uint32)
```

Returns the last repaid timestamp of the loan.

_Return type is of uint32._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint32 | timestamp in uint32. |

### isPaymentLate

```solidity
function isPaymentLate(uint256 _loanId) public view returns (bool)
```

Checks if the loan repayment is late.

_Return type is of boolean._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | boolean indicating if the loan repayment is late. |

### calculateNextDueDate

```solidity
function calculateNextDueDate(uint256 _loanId) public view returns (uint32 dueDate_)
```

Calculates the next repayment due date.

_Return type is of uint32._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| dueDate_ | uint32 | The timestamp of the next payment due date. |

### viewInstallmentAmount

```solidity
function viewInstallmentAmount(uint256 _loanId) external view returns (uint256)
```

Returns the installment amount to be paid at the called timestamp.

_Return type is of uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 of the installment amount to be paid. |

### repayMonthlyInstallment

```solidity
function repayMonthlyInstallment(uint256 _loanId) external
```

Repays the monthly installment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

### viewFullRepayAmount

```solidity
function viewFullRepayAmount(uint256 _loanId) public view returns (uint256)
```

Returns the full amount to be paid at the called timestamp.

_Return type is of uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | uint256 of the full amount to be paid. |

### repayFullLoan

```solidity
function repayFullLoan(uint256 _loanId) external
```

Repays the full amount to be paid at the called timestamp.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |

### _repayLoan

```solidity
function _repayLoan(uint256 _loanId, struct poolStorage.Payment _payment, uint256 _owedAmount) internal
```

Repays the specified amount.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _loanId | uint256 | The Id of the loan. |
| _payment | struct poolStorage.Payment | The amount being paid split into principal and interest. |
| _owedAmount | uint256 | The total amount owed at the called timestamp. |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## poolRegistry

### attestationService

```solidity
contract AttestationServices attestationService
```

### lenderAttestationSchemaId

```solidity
bytes32 lenderAttestationSchemaId
```

### borrowerAttestationSchemaId

```solidity
bytes32 borrowerAttestationSchemaId
```

### AconomyFeeAddress

```solidity
address AconomyFeeAddress
```

### FundingPoolAddress

```solidity
address FundingPoolAddress
```

### poolCount

```solidity
uint256 poolCount
```

### poolDetail

```solidity
struct poolDetail {
  address poolAddress;
  address owner;
  string URI;
  uint16 APR;
  uint16 poolFeePercent;
  bool lenderAttestationRequired;
  struct EnumerableSet.AddressSet verifiedLendersForPool;
  mapping(address => bytes32) lenderAttestationIds;
  uint32 paymentCycleDuration;
  uint32 paymentDefaultDuration;
  uint32 loanExpirationTime;
  bool borrowerAttestationRequired;
  struct EnumerableSet.AddressSet verifiedBorrowersForPool;
  mapping(address => bytes32) borrowerAttestationIds;
}
```

### pools

```solidity
mapping(uint256 => struct poolRegistry.poolDetail) pools
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(contract AttestationServices _attestationServices, address _AconomyFee, address _FundingPoolAddress) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### lenderOrBorrowerSchema

```solidity
modifier lenderOrBorrowerSchema(bytes32 schemaId)
```

### ownsPool

```solidity
modifier ownsPool(uint256 _poolId)
```

### changeFundingPoolImplementation

```solidity
function changeFundingPoolImplementation(address newFundingPool) external
```

### poolCreated

```solidity
event poolCreated(address owner, address poolAddress, uint256 poolId, string URI)
```

### SetPaymentCycleDuration

```solidity
event SetPaymentCycleDuration(uint256 poolId, uint32 duration)
```

### SetPaymentDefaultDuration

```solidity
event SetPaymentDefaultDuration(uint256 poolId, uint32 duration)
```

### SetPoolFee

```solidity
event SetPoolFee(uint256 poolId, uint16 feePct)
```

### SetloanExpirationTime

```solidity
event SetloanExpirationTime(uint256 poolId, uint32 duration)
```

### LenderAttestation

```solidity
event LenderAttestation(uint256 poolId, address lender)
```

### BorrowerAttestation

```solidity
event BorrowerAttestation(uint256 poolId, address borrower)
```

### LenderRevocation

```solidity
event LenderRevocation(uint256 poolId, address lender)
```

### BorrowerRevocation

```solidity
event BorrowerRevocation(uint256 poolId, address borrower)
```

### SetPoolURI

```solidity
event SetPoolURI(uint256 poolId, string uri)
```

### SetAPR

```solidity
event SetAPR(uint256 poolId, uint16 APR)
```

### poolClosed

```solidity
event poolClosed(uint256 poolId)
```

### createPool

```solidity
function createPool(uint32 _paymentDefaultDuration, uint32 _loanExpirationTime, uint16 _poolFeePercent, uint16 _apr, string _uri, bool _requireLenderAttestation, bool _requireBorrowerAttestation) external returns (uint256 poolId_)
```

Creates a new pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _paymentDefaultDuration | uint32 | Length of time in seconds before a loan is considered in default for non-payment. |
| _loanExpirationTime | uint32 | Length of time in seconds before pending loan expire. |
| _poolFeePercent | uint16 | The pool fee percentage in bps. |
| _apr | uint16 | The desired pool apr. |
| _uri | string | The pool uri. |
| _requireLenderAttestation | bool | Boolean that indicates if lenders require attestation to join pool. |
| _requireBorrowerAttestation | bool | Boolean that indicates if borrowers require attestation to join pool. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| poolId_ | uint256 | The market ID of the newly created pool. |

### setApr

```solidity
function setApr(uint256 _poolId, uint16 _apr) public
```

Sets the desired pool apr.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _apr | uint16 | The apr to be set. |

### setPoolURI

```solidity
function setPoolURI(uint256 _poolId, string _uri) public
```

Sets the pool uri.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _uri | string | The uri to be set. |

### setPaymentDefaultDuration

```solidity
function setPaymentDefaultDuration(uint256 _poolId, uint32 _duration) public
```

Sets the pool payment default duration.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _duration | uint32 | The duration to be set. |

### setPoolFeePercent

```solidity
function setPoolFeePercent(uint256 _poolId, uint16 _newPercent) public
```

Sets the pool fee percent.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _newPercent | uint16 | The new percent to be set. |

### setloanExpirationTime

```solidity
function setloanExpirationTime(uint256 _poolId, uint32 _duration) public
```

Sets the desired loan expiration time.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _duration | uint32 | the duration for expiration. |

### changePoolSetting

```solidity
function changePoolSetting(uint256 _poolId, uint32 _paymentDefaultDuration, uint32 _loanExpirationTime, uint16 _poolFeePercent, uint16 _apr, string _uri) public
```

Change the details of existing pool.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the existing pool. |
| _paymentDefaultDuration | uint32 | Length of time in seconds before a loan is considered in default for non-payment. |
| _loanExpirationTime | uint32 | Length of time in seconds before pending loan expire. |
| _poolFeePercent | uint16 | The pool fee percentage in bps. |
| _apr | uint16 | The desired pool apr. |
| _uri | string | The pool uri. |

### addLender

```solidity
function addLender(uint256 _poolId, address _lenderAddress) public
```

Adds a lender to the pool.

_Only called by the pool owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _lenderAddress | address | The address of the lender. |

### addBorrower

```solidity
function addBorrower(uint256 _poolId, address _borrowerAddress) public
```

Adds a borrower to the pool.

_Only called by the pool owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _borrowerAddress | address | The address of the borrower. |

### removeLender

```solidity
function removeLender(uint256 _poolId, address _lenderAddress) external
```

Removes a lender from the pool.

_Only called by the pool owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _lenderAddress | address | The address of the lender. |

### removeBorrower

```solidity
function removeBorrower(uint256 _poolId, address _borrowerAddress) external
```

Removes a borrower from the pool.

_Only called by the pool owner_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _borrowerAddress | address | The address of the borrower. |

### _attestAddress

```solidity
function _attestAddress(uint256 _poolId, address _Address, bool _isLender) internal
```

Attests an address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _Address | address | The address being attested. |
| _isLender | bool | Boolean indicating if the address is a lender |

### _attestAddressVerification

```solidity
function _attestAddressVerification(uint256 _poolId, address _Address, bytes32 _uuid, bool _isLender) internal
```

Verifies the address in poolRegistry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _Address | address | The address being attested. |
| _uuid | bytes32 | The uuid of the attestation. |
| _isLender | bool | Boolean indicating if the address is a lender |

### _revokeAddress

```solidity
function _revokeAddress(uint256 _poolId, address _address, bool _isLender) internal virtual
```

Revokes an address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _address | address | The address being revoked. |
| _isLender | bool | Boolean indicating if the address is a lender |

### _revokeAddressVerification

```solidity
function _revokeAddressVerification(uint256 _poolId, address _Address, bool _isLender) internal virtual returns (bytes32 uuid_)
```

Verifies the address being revoked in poolRegistry.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _Address | address | The address being revoked. |
| _isLender | bool | Boolean indicating if the address is a lender |

### getPoolFee

```solidity
function getPoolFee(uint256 _poolId) public view returns (uint16 fee)
```

### borrowerVerification

```solidity
function borrowerVerification(uint256 _poolId, address _borrowerAddress) public view returns (bool isVerified_, bytes32 uuid_)
```

Checks if the address is a verified borrower.

_returns a boolean and byte32 uuid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _borrowerAddress | address | The address being verified. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isVerified_ | bool | boolean and byte32 uuid_. |
| uuid_ | bytes32 |  |

### lenderVerification

```solidity
function lenderVerification(uint256 _poolId, address _lenderAddress) public view returns (bool isVerified_, bytes32 uuid_)
```

Checks if the address is a verified lender.

_returns a boolean and byte32 uuid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |
| _lenderAddress | address | The address being verified. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isVerified_ | bool | boolean and byte32 uuid_. |
| uuid_ | bytes32 |  |

### _isAddressVerified

```solidity
function _isAddressVerified(address _wltAddress, bool _attestationRequired, mapping(address => bytes32) _stakeholderAttestationIds, struct EnumerableSet.AddressSet _verifiedStakeholderForPool) internal view returns (bool isVerified_, bytes32 uuid_)
```

Checks if the address is verified.

_returns a boolean and byte32 uuid._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _wltAddress | address | The address being checked. |
| _attestationRequired | bool | The need for attestation for the pool. |
| _stakeholderAttestationIds | mapping(address &#x3D;&gt; bytes32) | The uuid's of the verified pool addresses |
| _verifiedStakeholderForPool | struct EnumerableSet.AddressSet | The addresses of the pool |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| isVerified_ | bool | boolean and byte32 uuid_. |
| uuid_ | bytes32 |  |

### closePool

```solidity
function closePool(uint256 _poolId) public
```

Closes the pool specified.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolId | uint256 | The Id of the pool. |

### ClosedPool

```solidity
function ClosedPool(uint256 _poolId) public view returns (bool)
```

### getPaymentCycleDuration

```solidity
function getPaymentCycleDuration(uint256 _poolId) public view returns (uint32)
```

### getPaymentDefaultDuration

```solidity
function getPaymentDefaultDuration(uint256 _poolId) public view returns (uint32)
```

### getloanExpirationTime

```solidity
function getloanExpirationTime(uint256 poolId) public view returns (uint32)
```

### getPoolUri

```solidity
function getPoolUri(uint256 _poolId) public view returns (string)
```

### getPoolAddress

```solidity
function getPoolAddress(uint256 _poolId) public view returns (address)
```

### getPoolOwner

```solidity
function getPoolOwner(uint256 _poolId) public view returns (address)
```

### getPoolApr

```solidity
function getPoolApr(uint256 _poolId) public view returns (uint16)
```

### getPoolFeePercent

```solidity
function getPoolFeePercent(uint256 _poolId) public view returns (uint16)
```

### getAconomyFee

```solidity
function getAconomyFee() public view returns (uint16)
```

### getAconomyOwner

```solidity
function getAconomyOwner() public view returns (address)
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## poolStorage

### loanId

```solidity
uint256 loanId
```

### loans

```solidity
mapping(uint256 => struct poolStorage.Loan) loans
```

### poolLoans

```solidity
mapping(uint256 => uint256) poolLoans
```

### LoanState

```solidity
enum LoanState {
  PENDING,
  CANCELLED,
  ACCEPTED,
  PAID
}
```

### Payment

```solidity
struct Payment {
  uint256 principal;
  uint256 interest;
}
```

### LoanDetails

```solidity
struct LoanDetails {
  contract ERC20 lendingToken;
  uint256 principal;
  struct poolStorage.Payment totalRepaid;
  uint32 timestamp;
  uint32 acceptedTimestamp;
  uint32 lastRepaidTimestamp;
  uint32 loanDuration;
  uint16 protocolFee;
}
```

### Terms

```solidity
struct Terms {
  uint256 paymentCycleAmount;
  uint256 monthlyCycleInterest;
  uint32 paymentCycle;
  uint16 APR;
  uint32 installments;
  uint32 installmentsPaid;
}
```

### Loan

```solidity
struct Loan {
  address borrower;
  address receiver;
  address lender;
  uint256 poolId;
  struct poolStorage.LoanDetails loanDetails;
  struct poolStorage.Terms terms;
  enum poolStorage.LoanState state;
}
```

### borrowerActiveLoans

```solidity
mapping(address => struct EnumerableSet.UintSet) borrowerActiveLoans
```

### totalERC20Amount

```solidity
mapping(address => uint256) totalERC20Amount
```

### borrowerLoans

```solidity
mapping(address => uint256[]) borrowerLoans
```

### loanDefaultDuration

```solidity
mapping(uint256 => uint32) loanDefaultDuration
```

### loanExpirationDuration

```solidity
mapping(uint256 => uint32) loanExpirationDuration
```

### lenderLendAmount

```solidity
mapping(address => mapping(address => uint256)) lenderLendAmount
```

### poolRegistryAddress

```solidity
address poolRegistryAddress
```

### AconomyFeeAddress

```solidity
address AconomyFeeAddress
```

## AconomyERC2771Context

_Context variant with ERC2771 support._

### trustedForwarders

```solidity
mapping(address => bool) trustedForwarders
```

### AconomyERC2771Context_init

```solidity
function AconomyERC2771Context_init(address tfGelato) internal
```

### isTrustedForwarder

```solidity
function isTrustedForwarder(address forwarder) public view virtual returns (bool)
```

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address sender)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

### addTrustedForwarder

```solidity
function addTrustedForwarder(address _tf) external
```

### removeTrustedForwarder

```solidity
function removeTrustedForwarder(address _tf) external
```

## CollectionFactory

### CollectionMeta

```solidity
struct CollectionMeta {
  string name;
  string symbol;
  string URI;
  address contractAddress;
  address owner;
  string description;
}
```

### collections

```solidity
mapping(uint256 => struct CollectionFactory.CollectionMeta) collections
```

### addressToCollectionId

```solidity
mapping(address => uint256) addressToCollectionId
```

### royaltiesForCollection

```solidity
mapping(uint256 => struct LibShare.Share[]) royaltiesForCollection
```

### collectionId

```solidity
uint256 collectionId
```

### collectionMethodAddress

```solidity
address collectionMethodAddress
```

### piNFTMethodsAddress

```solidity
address piNFTMethodsAddress
```

### CollectionURISet

```solidity
event CollectionURISet(uint256 collectionId, string uri)
```

### CollectionNameSet

```solidity
event CollectionNameSet(uint256 collectionId, string name)
```

### CollectionDescriptionSet

```solidity
event CollectionDescriptionSet(uint256 collectionId, string Description)
```

### CollectionSymbolSet

```solidity
event CollectionSymbolSet(uint256 collectionId, string Symbol)
```

### CollectionCreated

```solidity
event CollectionCreated(uint256 collectionId, address CollectionAddress, string URI)
```

### CollectionRoyaltiesSet

```solidity
event CollectionRoyaltiesSet(uint256 collectionId, struct LibShare.Share[] royalties)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _collectionMethodAddress, address _piNFTMethodsAddress) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### collectionOwner

```solidity
modifier collectionOwner(uint256 _collectionId)
```

### changeCollectionMethodImplementation

```solidity
function changeCollectionMethodImplementation(address newCollectionMethods) external
```

### createCollection

```solidity
function createCollection(string _name, string _symbol, string _uri, string _description, struct LibShare.Share[] royalties) public returns (uint256 collectionId_)
```

Creates and deploys a collection and returns the collection Id.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | The name of the collection. |
| _symbol | string | The symbol of the collection. |
| _uri | string | The collection uri. |
| _description | string | The collection description. |
| royalties | struct LibShare.Share[] | The collection royalties. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| collectionId_ | uint256 | . |

### setRoyaltiesForCollection

```solidity
function setRoyaltiesForCollection(uint256 _collectionId, struct LibShare.Share[] royalties) public
```

Sets the collection royalties.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |
| royalties | struct LibShare.Share[] | The royalties to be set for the collection. |

### setCollectionURI

```solidity
function setCollectionURI(uint256 _collectionId, string _uri) public
```

Sets the collection uri.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |
| _uri | string | The uri to be set. |

### setCollectionName

```solidity
function setCollectionName(uint256 _collectionId, string _name) public
```

Sets the collection name.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |
| _name | string | The name to be set. |

### setCollectionSymbol

```solidity
function setCollectionSymbol(uint256 _collectionId, string _symbol) public
```

Sets the collection symbol.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |
| _symbol | string | The collection symbol to be set. |

### setCollectionDescription

```solidity
function setCollectionDescription(uint256 _collectionId, string _description) public
```

Sets the collection description.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |
| _description | string | The collection description to be set. |

### getCollectionRoyalties

```solidity
function getCollectionRoyalties(uint256 _collectionId) external view returns (struct LibShare.Share[])
```

Fetches the collection royalties.

_Returns a LibShare.Share[] array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionId | uint256 | The id of the collection. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibShare.Share[] | A LibShare.Share[] struct array of royalties. |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## CollectionMethods

### collectionOwner

```solidity
address collectionOwner
```

### collectionFactoryAddress

```solidity
address collectionFactoryAddress
```

### RoyaltiesForValidator

```solidity
mapping(uint256 => struct LibShare.Share[]) RoyaltiesForValidator
```

### RoyaltiesSet

```solidity
event RoyaltiesSet(uint256 tokenId, struct LibShare.Share[] royalties)
```

### TokenMinted

```solidity
event TokenMinted(uint256 tokenId, address to, string URI)
```

### onlyMethods

```solidity
modifier onlyMethods()
```

Modifier enabling only the piNFTMethods contract to call.

### initialize

```solidity
function initialize(address _collectionOwner, address _collectionFactoryAddress, string _name, string _symbol) external
```

Contract initializer.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionOwner | address | The address set to own the collection. |
| _collectionFactoryAddress | address | The address of the CollectionFactory contract. |
| _name | string | the name of the collection being created. |
| _symbol | string | the symbol of the collection being created. |

### onlyOwnerOfToken

```solidity
modifier onlyOwnerOfToken(uint256 _tokenId)
```

### mintNFT

```solidity
function mintNFT(address _to, string _uri) public
```

Mints an nft to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | address to mint the piNFT to. |
| _uri | string | The uri of the piNFT. |

### setRoyaltiesForValidator

```solidity
function setRoyaltiesForValidator(uint256 _tokenId, uint256 _commission, struct LibShare.Share[] royalties) external
```

Checks and sets validator royalties.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |
| _commission | uint256 |  |
| royalties | struct LibShare.Share[] | The royalties to be set. |

### deleteValidatorRoyalties

```solidity
function deleteValidatorRoyalties(uint256 _tokenId) external
```

### deleteNFT

```solidity
function deleteNFT(uint256 _tokenId) external
```

deletes the nft.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |

### exists

```solidity
function exists(uint256 _tokenId) external view returns (bool)
```

### getValidatorRoyalties

```solidity
function getValidatorRoyalties(uint256 _tokenId) external view returns (struct LibShare.Share[])
```

Fetches the validator royalties.

_Returns a LibShare.Share[] array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The id of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibShare.Share[] | A LibShare.Share[] struct array of royalties. |

## LibCollection

### deployCollectionAddress

```solidity
function deployCollectionAddress(address _collectionOwner, address _collectionFactoryAddress, string _name, string _symbol, address _collectionMethods) external returns (address)
```

Returns the address of the deployed collection contract.

_Returned value is type address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionOwner | address | The address set to own the collection. |
| _collectionFactoryAddress | address | The address of the CollectionFactory contract. |
| _name | string | the name of the collection being created. |
| _symbol | string | the symbol of the collection being created. |
| _collectionMethods | address | the address of the proxy implementation CollectionMethods contract. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | address of the deployed collection. |

## LibMarket

### checkSale

```solidity
function checkSale(struct piMarket.TokenMeta meta) external view
```

Checks the requiments for a sale to go through.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meta | struct piMarket.TokenMeta | The metadata of the sale being bought. |

### executeSale

```solidity
function executeSale(struct piMarket.TokenMeta meta, address AconomyFeeAddress, address piNFTMethodsAddress, struct LibShare.Share[] royalties, struct LibShare.Share[] validatorRoyalties) external
```

Executes the sale from the given sale metadata.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meta | struct piMarket.TokenMeta | The metadata of the sale being executed. |
| AconomyFeeAddress | address | The address of AconomyFee contract. |
| piNFTMethodsAddress | address |  |
| royalties | struct LibShare.Share[] | The token or collection royalties. |
| validatorRoyalties | struct LibShare.Share[] | the piNFT validatorRoyalties. |

### checkBid

```solidity
function checkBid(struct piMarket.TokenMeta meta, uint256 amount) external view
```

Checks the requirments for submission of a bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meta | struct piMarket.TokenMeta | The metadata of the sale on which the bid is being placed. |
| amount | uint256 | The amount being bidded. |

### executeBid

```solidity
function executeBid(struct piMarket.TokenMeta meta, struct piMarket.BidOrder bids, struct LibShare.Share[] royalties, struct LibShare.Share[] validatorRoyalties, address piNFTMethodsAddress, address AconomyFeeAddress) external
```

executes the the sale with a selected bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meta | struct piMarket.TokenMeta | The metadata of the sale being executed. |
| bids | struct piMarket.BidOrder | The metadata of the bid being executed. |
| royalties | struct LibShare.Share[] | The token royalties. |
| validatorRoyalties | struct LibShare.Share[] | The piNFT validator royalties. |
| piNFTMethodsAddress | address |  |
| AconomyFeeAddress | address | The address of AconomyFee contract. |

### withdrawBid

```solidity
function withdrawBid(struct piMarket.TokenMeta meta, struct piMarket.BidOrder bids) external
```

Withdraws a selected bid as long as it has not been executed for a sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| meta | struct piMarket.TokenMeta | The metadata of the sale for which the bid has been placed. |
| bids | struct piMarket.BidOrder | The metadata of the bid being withdrawn. |

## piMarket

### _saleIdCounter

```solidity
struct Counters.Counter _saleIdCounter
```

### TokenMeta

```solidity
struct TokenMeta {
  uint256 saleId;
  address tokenContractAddress;
  uint256 tokenId;
  uint256 price;
  bool directSale;
  bool bidSale;
  bool status;
  uint256 bidStartTime;
  uint256 bidEndTime;
  address currentOwner;
  address currency;
}
```

### BidOrder

```solidity
struct BidOrder {
  uint256 bidId;
  uint256 saleId;
  address sellerAddress;
  address buyerAddress;
  uint256 price;
  bool withdrawn;
}
```

### Swap

```solidity
struct Swap {
  address initiatorNFTAddress;
  address initiator;
  uint256 initiatorNftId;
  address requestedTokenOwner;
  uint256 requestedTokenId;
  address requestedTokenAddress;
  bool status;
}
```

### _tokenMeta

```solidity
mapping(uint256 => struct piMarket.TokenMeta) _tokenMeta
```

### Bids

```solidity
mapping(uint256 => struct piMarket.BidOrder[]) Bids
```

### SaleCreated

```solidity
event SaleCreated(uint256 tokenId, address tokenContract, uint256 saleId, uint256 BidTimeDuration, uint256 Price)
```

### NFTBought

```solidity
event NFTBought(uint256 tokenId, address collectionAddress)
```

### SaleCancelled

```solidity
event SaleCancelled(uint256 saleId)
```

### BidEvent

```solidity
event BidEvent(uint256 tokenId, uint256 saleId, uint256 bidId, uint256 Amount, address collectionAddress, bool BidCreated)
```

### BidWithdrawn

```solidity
event BidWithdrawn(uint256 saleId, uint256 bidId)
```

### SwapCancelled

```solidity
event SwapCancelled(uint256 swapId)
```

### SwapAccepted

```solidity
event SwapAccepted(uint256 swapId)
```

### SwapProposed

```solidity
event SwapProposed(address to, uint256 swapId, uint256 outTokenId, address outTokenIdAddress, uint256 inTokenId, address inTokenIdAddress)
```

### updatedSalePrice

```solidity
event updatedSalePrice(uint256 saleId, uint256 Price, uint256 Duration)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _feeAddress, address _collectionFactoryAddress, address _piNFTMethodsAddress) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### onlyOwnerOfToken

```solidity
modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId)
```

### sellNFT

```solidity
function sellNFT(address _contractAddress, uint256 _tokenId, uint256 _price, address _currency) external
```

Puts an nft on sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _contractAddress | address | the address of the token contract. |
| _tokenId | uint256 | The Id of the token. |
| _price | uint256 | The price the token is to be listed at. |
| _currency | address | The currency being used. |

### editSalePrice

```solidity
function editSalePrice(uint256 _saleId, uint256 _price, uint256 _duration) public
```

Edits the price of the sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |
| _price | uint256 | The new price being set. |
| _duration | uint256 |  |

### retrieveRoyalty

```solidity
function retrieveRoyalty(address _contractAddress, uint256 _tokenId) public view returns (struct LibShare.Share[])
```

Retrieves the token royalty.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _contractAddress | address | the address of the token contract. |
| _tokenId | uint256 | The Id of the token. |

### getCollectionRoyalty

```solidity
function getCollectionRoyalty(address _collectionFactoryAddress, address _collectionAddress) public view returns (struct LibShare.Share[])
```

Fetches the collection royalty.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionFactoryAddress | address | The address of the CollectionFactory. |
| _collectionAddress | address | The address of the collection. |

### getCollectionValidatorRoyalty

```solidity
function getCollectionValidatorRoyalty(address _collectionAddress, uint256 _tokenId) public view returns (struct LibShare.Share[])
```

Fetches the collection validator royalty.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The Id of the token. |

### retrieveValidatorRoyalty

```solidity
function retrieveValidatorRoyalty(address _contractAddress, uint256 _tokenId) public view returns (struct LibShare.Share[])
```

Retrieves the validator royalty.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _contractAddress | address | the address of the token contract. |
| _tokenId | uint256 | The Id of the token. |

### BuyNFT

```solidity
function BuyNFT(uint256 _saleId, bool _fromCollection) external payable
```

Allows a user to buy an nft on sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |
| _fromCollection | bool | A boolean indicating if the nft is from a priavte collection. |

### cancelSale

```solidity
function cancelSale(uint256 _saleId) external
```

Cancels a sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |

### SellNFT_byBid

```solidity
function SellNFT_byBid(address _contractAddress, uint256 _tokenId, uint256 _price, uint256 _bidTime, address _currency) external
```

Puts an nft on auction.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _contractAddress | address | the address of the token contract. |
| _tokenId | uint256 | The Id of the token. |
| _price | uint256 | The price the token is to be listed at. |
| _bidTime | uint256 | The duration time of the auction. |
| _currency | address | The currency being used. |

### Bid

```solidity
function Bid(uint256 _saleId, uint256 _bidPrice) external payable
```

Places a bid on an auction sale.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |
| _bidPrice | uint256 | The amount being bidded |

### executeBidOrder

```solidity
function executeBidOrder(uint256 _saleId, uint256 _bidOrderID, bool _fromCollection) external
```

executes a sale with a specified bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |
| _bidOrderID | uint256 | The Id of the bid. |
| _fromCollection | bool | Boolean indicating if the nft is from a private collection. |

### withdrawBidMoney

```solidity
function withdrawBidMoney(uint256 _saleId, uint256 _bidId) external
```

executes a sale with a specified bid.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _saleId | uint256 | The Id of the sale. |
| _bidId | uint256 | The Id of the bid. |

### makeSwapRequest

```solidity
function makeSwapRequest(address contractAddress1, address contractAddress2, uint256 token1, uint256 token2) public returns (uint256)
```

Makes a swap request.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| contractAddress1 | address | The contract address of the first token. |
| contractAddress2 | address | The contract address of the second token. |
| token1 | uint256 | The token Id of the token whose owner is making the request. |
| token2 | uint256 | The token Id of the token being requested for the swap. |

### cancelSwap

```solidity
function cancelSwap(uint256 _swapId) public
```

Cancels a swap.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _swapId | uint256 | The Id of the swap. |

### acceptSwapRequest

```solidity
function acceptSwapRequest(uint256 swapId) public
```

Accepts and executes a swap.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| swapId | uint256 | The Id of the swap. |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## piNFT

### piNFTMethodsAddress

```solidity
address piNFTMethodsAddress
```

### royaltiesByTokenId

```solidity
mapping(uint256 => struct LibShare.Share[]) royaltiesByTokenId
```

### royaltiesForValidator

```solidity
mapping(uint256 => struct LibShare.Share[]) royaltiesForValidator
```

### RoyaltiesSetForTokenId

```solidity
event RoyaltiesSetForTokenId(uint256 tokenId, struct LibShare.Share[] royalties)
```

### RoyaltiesSetForValidator

```solidity
event RoyaltiesSetForValidator(uint256 tokenId, struct LibShare.Share[] royalties)
```

### TokenMinted

```solidity
event TokenMinted(uint256 tokenId, address to, string uri)
```

### onlyMethods

```solidity
modifier onlyMethods()
```

Modifier enabling only the piNFTMethods contract to call.

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(string _name, string _symbol, address _piNFTMethodsAddress, address tfGelato) public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### mintNFT

```solidity
function mintNFT(address _to, string _uri, struct LibShare.Share[] royalties) public returns (uint256)
```

Mints an nft to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | address to mint the piNFT to. |
| _uri | string | The uri of the piNFT. |
| royalties | struct LibShare.Share[] | The royalties being set for the token |

### lazyMintNFT

```solidity
function lazyMintNFT(address _to, string _uri, struct LibShare.Share[] royalties) external returns (uint256)
```

Lazy Mints an nft to a specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _to | address | address to mint the piNFT to. |
| _uri | string | The uri of the piNFT. |
| royalties | struct LibShare.Share[] | The royalties being set for the token |

### _setRoyaltiesByTokenId

```solidity
function _setRoyaltiesByTokenId(uint256 _tokenId, struct LibShare.Share[] royalties) internal
```

Checks and sets token royalties.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |
| royalties | struct LibShare.Share[] | The royalties to be set. |

### getRoyalties

```solidity
function getRoyalties(uint256 _tokenId) external view returns (struct LibShare.Share[])
```

Fetches the token royalties.

_Returns a LibShare.Share[] array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The id of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibShare.Share[] | A LibShare.Share[] struct array of royalties. |

### getValidatorRoyalties

```solidity
function getValidatorRoyalties(uint256 _tokenId) external view returns (struct LibShare.Share[])
```

Fetches the validator royalties.

_Returns a LibShare.Share[] array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The id of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibShare.Share[] | A LibShare.Share[] struct array of royalties. |

### setRoyaltiesForValidator

```solidity
function setRoyaltiesForValidator(uint256 _tokenId, uint256 _commission, struct LibShare.Share[] royalties) external
```

Checks and sets validator royalties.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |
| _commission | uint256 |  |
| royalties | struct LibShare.Share[] | The royalties to be set. |

### deleteValidatorRoyalties

```solidity
function deleteValidatorRoyalties(uint256 _tokenId) external
```

### deleteNFT

```solidity
function deleteNFT(uint256 _tokenId) external
```

deletes the nft.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |

### exists

```solidity
function exists(uint256 _tokenId) external view returns (bool)
```

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address sender)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## piNFTMethods

### piMarketAddress

```solidity
address piMarketAddress
```

### erc20Balances

```solidity
mapping(address => mapping(uint256 => mapping(address => uint256))) erc20Balances
```

### erc20ContractIndex

```solidity
mapping(address => mapping(uint256 => mapping(address => uint256))) erc20ContractIndex
```

### NFTowner

```solidity
mapping(address => mapping(uint256 => address)) NFTowner
```

### withdrawnAmount

```solidity
mapping(address => mapping(uint256 => uint256)) withdrawnAmount
```

### approvedValidator

```solidity
mapping(address => mapping(uint256 => address)) approvedValidator
```

### validatorCommissions

```solidity
mapping(address => mapping(uint256 => struct piNFTMethods.Commission)) validatorCommissions
```

### Commission

```solidity
struct Commission {
  struct LibShare.Share commission;
  bool isValid;
}
```

### ERC20Added

```solidity
event ERC20Added(address collectionAddress, address from, uint256 tokenId, address erc20Contract, uint256 value, string URI, uint256 TotalBalance)
```

### ERC20Transferred

```solidity
event ERC20Transferred(address collectionAddress, uint256 tokenId, address to, address erc20Contract, uint256 value)
```

### PiNFTRedeemed

```solidity
event PiNFTRedeemed(address collectionAddress, uint256 tokenId, address nftReciever, address validatorAddress, address erc20Contract, uint256 value)
```

### PiNFTBurnt

```solidity
event PiNFTBurnt(address collectionAddress, uint256 tokenId, address nftReciever, address erc20Receiver, address erc20Contract, uint256 value)
```

### ValidatorFundsWithdrawn

```solidity
event ValidatorFundsWithdrawn(address collectionAddress, address withdrawer, uint256 tokenId, address erc20Contract, uint256 amount)
```

### ValidatorFundsRepayed

```solidity
event ValidatorFundsRepayed(address collectionAddress, address repayer, uint256 tokenId, address erc20Contract, uint256 amount)
```

### ValidatorAdded

```solidity
event ValidatorAdded(address collectionAddress, uint256 tokenId, address validator)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address trustedForwarder) public
```

### setPiMarket

```solidity
function setPiMarket(address _piMarket) external
```

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address sender)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### addValidator

```solidity
function addValidator(address _collectionAddress, uint256 _tokenId, address _validator) external
```

### lazyAddValidator

```solidity
function lazyAddValidator(address _collectionAddress, uint256 _tokenId, address _validator) external
```

### addERC20

```solidity
function addERC20(address _collectionAddress, uint256 _tokenId, address _erc20Contract, uint256 _value, uint96 _commission, string _uri, struct LibShare.Share[] royalties) public
```

Allows the validator to deposit funds to validate the piNFT.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The ID of the token. |
| _erc20Contract | address | The address of the funds being deposited. |
| _value | uint256 | The amount of funds being deposited. |
| _commission | uint96 | The commission of validator. |
| _uri | string |  |
| royalties | struct LibShare.Share[] | The validator royalties. |

### redeemOrBurnPiNFT

```solidity
function redeemOrBurnPiNFT(address _collectionAddress, uint256 _tokenId, address _nftReceiver, address _erc20Receiver, address _erc20Contract, bool burnNFT) external
```

Allows the nft owner to redeem or burn the piNFT.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The Id of the token. |
| _nftReceiver | address | The receiver of the nft after the function call. |
| _erc20Receiver | address | The receiver of the validator funds after the function call. |
| _erc20Contract | address | The address of the deposited validator funds. |
| burnNFT | bool | Boolean to determine redeeming or burning. |

### viewBalance

```solidity
function viewBalance(address _collectionAddress, uint256 _tokenId, address _erc20Address) public view returns (uint256)
```

Returns the specified ERC20 balance of the token.

_Returned value is type uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The Id of the token. |
| _erc20Address | address | The address of the funds to be fetched. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | ERC20 balance of the token. |

### withdraw

```solidity
function withdraw(address _collectionAddress, uint256 _tokenId, address _erc20Contract, uint256 _amount) external
```

Allows the nft owner to lock the piNFT in the contract and withdraw validator funds.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The Id of the token. |
| _erc20Contract | address | The address of the funds being withdrawn. |
| _amount | uint256 | The amount of funds being withdrawn. |

### viewWithdrawnAmount

```solidity
function viewWithdrawnAmount(address _collectionAddress, uint256 _tokenId) public view returns (uint256)
```

Fetches the withdrawn amount for a token.

_Returns a uint256._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The id of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | A uint256 of withdrawn amount. |

### Repay

```solidity
function Repay(address _collectionAddress, uint256 _tokenId, address _erc20Contract, uint256 _amount) external
```

Repays the withdrawn validator funds and transfers back token on full repayment.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _collectionAddress | address | The address of the collection. |
| _tokenId | uint256 | The Id of the token. |
| _erc20Contract | address | The address of the funds to be repaid. |
| _amount | uint256 | The amount to be repaid. |

### paidCommission

```solidity
function paidCommission(address _collection, uint256 _tokenId) external
```

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## LibShare

### Share

```solidity
struct Share {
  address payable account;
  uint96 value;
}
```

### setCommission

```solidity
function setCommission(struct LibShare.Share _setShare, uint96 _commission) external
```

## validatedNFT

### constructor

```solidity
constructor() public
```

### piNFTMethodsAddress

```solidity
address piNFTMethodsAddress
```

### TokenMinted

```solidity
event TokenMinted(uint256 tokenId, address to)
```

### RoyaltiesSetForValidator

```solidity
event RoyaltiesSetForValidator(uint256 tokenId, struct LibShare.Share[] royalties)
```

### initialize

```solidity
function initialize(address _piNFTmethodAddress) public
```

### royaltiesForValidator

```solidity
mapping(uint256 => struct LibShare.Share[]) royaltiesForValidator
```

### onlyMethods

```solidity
modifier onlyMethods()
```

Modifier enabling only the piNFTMethods contract to call.

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### mintValidatedNFT

```solidity
function mintValidatedNFT(address _to, string _uri) public returns (uint256)
```

### exists

```solidity
function exists(uint256 _tokenId) external view returns (bool)
```

### setRoyaltiesForValidator

```solidity
function setRoyaltiesForValidator(uint256 _tokenId, uint256 _commission, struct LibShare.Share[] royalties) external
```

Checks and sets validator royalties.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |
| _commission | uint256 |  |
| royalties | struct LibShare.Share[] | The royalties to be set. |

### getRoyalties

```solidity
function getRoyalties(uint256 _tokenId) external pure returns (struct LibShare.Share[])
```

### deleteNFT

```solidity
function deleteNFT(uint256 _tokenId) external
```

deletes the nft.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The Id of the token. |

### getValidatorRoyalties

```solidity
function getValidatorRoyalties(uint256 _tokenId) external view returns (struct LibShare.Share[])
```

Fetches the validator royalties.

_Returns a LibShare.Share[] array._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _tokenId | uint256 | The id of the token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct LibShare.Share[] | A LibShare.Share[] struct array of royalties. |

### deleteValidatorRoyalties

```solidity
function deleteValidatorRoyalties(uint256 _tokenId) external
```

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) public virtual returns (bytes4)
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

## validatorStake

### StakeDetail

```solidity
struct StakeDetail {
  uint256 stakedAmount;
  uint256 refundedAmount;
  address ERC20Address;
}
```

### validatorStakes

```solidity
mapping(address => struct validatorStake.StakeDetail) validatorStakes
```

### Staked

```solidity
event Staked(address validator, address ERC20Address, uint256 amount, uint256 TotalStakedAmount, bool positionChange)
```

### RefundedStake

```solidity
event RefundedStake(address validator, address ERC20Address, uint256 refundedAmount, uint256 LeftStakedAmount)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### _stake

```solidity
function _stake(uint256 _amount, address _ERC20Address, address _validator, bool _paid) internal
```

### stake

```solidity
function stake(uint256 _amount, address _ERC20Address) external
```

### addStake

```solidity
function addStake(uint256 _amount, address _ERC20Address) external
```

### refundStake

```solidity
function refundStake(address _validatorAddress, address _ERC20Address, uint256 _refundAmount) external
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

## mintToken

### constructor

```solidity
constructor(uint256 initialSupply) public
```

### mint

```solidity
function mint(address _recipient, uint256 _amount) external
```

### getTime

```solidity
function getTime() external view returns (uint256)
```

## SampleERC20

### mint

```solidity
function mint(address _recipient, uint256 _amount) external
```

## validatorStake2

### StakeDetail

```solidity
struct StakeDetail {
  uint256 stakedAmount;
  uint256 refundedAmount;
  address ERC20Address;
}
```

### validatorStakes

```solidity
mapping(address => struct validatorStake2.StakeDetail) validatorStakes
```

### Staked

```solidity
event Staked(address validator, address ERC20Address, uint256 amount, uint256 TotalStakedAmount, bool positionChange)
```

### RefundedStake

```solidity
event RefundedStake(address validator, address ERC20Address, uint256 refundedAmount, uint256 LeftStakedAmount)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### pause

```solidity
function pause() external
```

### unpause

```solidity
function unpause() external
```

### _stake

```solidity
function _stake(uint256 _amount, address _ERC20Address, address _validator, bool _paid) internal
```

### stake

```solidity
function stake(uint256 _amount, address _ERC20Address) external
```

### addStake

```solidity
function addStake(uint256 _amount, address _ERC20Address) external
```

### refundStake

```solidity
function refundStake(address _validatorAddress, address _ERC20Address, uint256 _refundAmount) external
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address) internal
```

