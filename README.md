
SafeLend  Flash Loan Protocol

A battle-tested, production-grade flash loan protocol built on Stacks enabling strategic capital deployment for arbitrage operations.

 Overview

SafeLend  provides atomic flash loans with guaranteed sameblock repayment requirements, allowing sophisticated traders to access temporary capital for profitable arbitrage strategies without requiring collateral or longterm capital commitment.

 Key Features

 ⚡ Flash Loans
 Instantaneous capital provisioning within a single block
 No collateral requirements
 Atomic execution guarantees
 Configurable loan amounts

 🔒 Security
 Reentrancy protection via statebased loan tracking
 Strict repayment validation with amount verification
 Ownercontrolled fee collection
 Typesafe Clarity implementation with comprehensive error handling
 Immutable loan history for auditability

 📊 Analytics & Monitoring
 Realtime active loan status
 Protocolwide statistics (total loans, accumulated fees)
 Perborrower tracking (total borrowed, loan count, last execution)
 Complete loan history with timestamps and fee records

 💰 Fee System
 Dynamic fee calculation (5 basis points / 0.05%)
 Ownercontrolled fee withdrawal
 Transparent fee computation
 Accumulated fee tracking

 Smart Contract Functions

 Public Functions

 initiateflashloan(amount: uint, callbackdata: buff)
Initiates a new flash loan for the specified amount. Only one active loan per block.

Parameters:
 amount  Loan amount in smallest unit (must be > 0)
 callbackdata  Execution context data (max 2048 bytes)

Returns: (ok true) or error

Errors:
 ERRINVALIDAMOUNT (1004)  Amount is zero
 ERRLOANACTIVE (1002)  Another loan already active

 repayflashloan(amount: uint, fees: uint)
Completes flash loan repayment with principal and fees. Must be called in same block as initiation.

Parameters:
 amount  Principal repayment amount
 fees  Total fee amount (must be ≥ required fee)

Returns: (ok true) or error

Errors:
 ERRNOACTIVELOAN (1006)  No active loan
 ERRUNAUTHORIZED (1001)  Caller is not loan initiator
 ERRINSUFFICIENTREPAY (1003)  Amount or fees insufficient

 withdrawaccumulatedfees(amount: uint)
Owner function to withdraw accumulated protocol fees.

Parameters:
 amount  Fee amount to withdraw

Returns: (ok true) or error

Errors:
 ERRUNAUTHORIZED (1001)  Caller is not contract owner
 ERRINSUFFICIENTREPAY (1003)  Insufficient accumulated fees

 ReadOnly Functions

 getactiveloanstatus()
Returns current active loan state including borrower, amount, calculated fee, and initiation block.

 getprotocolstats()
Returns protocolwide metrics: total loans issued and accumulated fees.

 getborrowerstats(borrower: principal)
Returns borrowerspecific statistics: total amount borrowed, loan count, and last execution block.

 calculatefee(amount: uint)
Calculates the required fee for a given loan amount (5 bps).

 verifyexecutioncontext(expectedborrower: principal)
Validates that a borrower has an active loan in the current execution context.

 Usage Example

 Single Transaction Flash Loan Flow

clarity
;; 1. Borrow 10,000 STX
(contractcall? .strike initiateflashloan u10000000000 0x)

;; 2. Execute arbitrage (happens in same transaction)
;;  Use capital for profitable trade
;;  Receive proceeds

;; 3. Repay with fees (5 bps = 5000 STXsatoshis)
(contractcall? .strike repayflashloan u10000000000 u50000)


 Error Codes

 Code  Constant  Meaning

 1001  ERRUNAUTHORIZED  Caller lacks required permissions
 1002  ERRLOANACTIVE  Another loan already active in block
 1003  ERRINSUFFICIENTREPAY  Repayment amount insufficient
 1004  ERRINVALIDAMOUNT  Loan amount invalid (zero)
 1005  ERRCALLBACKFAILED  Callback execution failed
 1006  ERRNOACTIVELOAN  No active loan for caller


 Data Structures

 Active Loan State

 activeloanblock  Block height when loan initiated
 activeloanborrower  Principal of borrowing address
 activeloanamount  Principal amount borrowed


 Loan History Map

Records all completed loans with amount, fee, and execution timestamp.

 Borrower Statistics Map

Tracks perborrower metrics: cumulative borrowed, total loans, and last execution block.

 Configuration

 Constants

 FLASHLOANFEE  u5 (5 basis points = 0.05%)
 BASISPOINTS  u10000 (standard basis point denominator)
 CONTRACTOWNER  Set to txsender at deployment


 Modifying Fees

Update FLASHLOANFEE constant to change fee percentage:

plaintext
(defineconstant FLASHLOANFEE u10) ;; 10 bps = 0.1%


 Testing

 Prerequisites

 Clarinet CLI installed
 Stacks development environment


 Run Checks

shellscript
clarinet check


All checks pass with zero errors or warnings.

 Run Tests

shellscript
clarinet test


 Security Considerations

1. Reentrancy Protection  Statebased tracking prevents nested loans within single block
2. Atomic Execution  All operations complete within same transaction block
3. Fee Collection  Validated and accumulated before loan completion
4. History Immutability  All loans recorded for auditing purposes
5. Access Control  Only borrowers can repay their loans; only owner withdraws fees


 Deployment

 Testnet

shellscript
clarinet deploy network testnet


 Mainnet

shellscript
clarinet deploy network mainnet


 Roadmap

 Multiasset flash loan support
 Dynamic fee tiers based on loan size
 Flashloan aggregation pool
 Integration with DEX protocols
 Advanced fee distribution mechanisms


 Contributing

1. Create feature branch: git checkout b feature/improvement
2. Implement changes following Clarity best practices
3. Run clarinet check and ensure zero warnings
4. Submit PR with detailed description
5. Code review and merge


 License

MIT
