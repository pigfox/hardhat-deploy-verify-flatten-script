// Sources flattened with hardhat v2.22.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/Arbitrage.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address owner) external view returns (uint);
}

interface IFlashLoanProvider {
    function flashLoan(
        address token,
        uint amount,
        bytes calldata data
    ) external;
}

interface IUniswap {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Arbitrage {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }

    function executeArbitrage(
        address flashLoanProviderAddress,
        address token,
        uint loanAmount,
        address[] calldata fromPath,
        address[] calldata toPath,
        uint amountOutMinFrom,
        uint amountOutMinTo,
        address fromDex,
        address toDex
    ) external onlyOwner {
        bytes memory data = abi.encode(
            token,
            loanAmount,
            fromPath,
            toPath,
            amountOutMinFrom,
            amountOutMinTo,
            fromDex,
            toDex
        );
        IFlashLoanProvider(flashLoanProviderAddress).flashLoan(
            token,
            loanAmount,
            data
        );
    }

    function onFlashLoanCallback(
        address token,
        uint, // Omitting name for unused parameter
        bytes calldata data
    ) external {
        (
            ,
            uint _loanAmount,
            address[] memory fromPath,
            address[] memory toPath,
            uint amountOutMinFrom,
            uint amountOutMinTo,
            address fromDex,
            address toDex
        ) = abi.decode(
                data,
                (
                    address,
                    uint,
                    address[],
                    address[],
                    uint,
                    uint,
                    address,
                    address
                )
            );

        IERC20(token).approve(fromDex, _loanAmount);
        IUniswap(fromDex).swapExactTokensForTokens(
            _loanAmount,
            amountOutMinFrom,
            fromPath,
            address(this),
            block.timestamp
        );

        uint amountReceived = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(toDex, amountReceived);
        IUniswap(toDex).swapExactTokensForTokens(
            amountReceived,
            amountOutMinTo,
            toPath,
            address(this),
            block.timestamp
        );

        uint profit = IERC20(token).balanceOf(address(this)) - _loanAmount;
        require(profit > 0, "No profit made");

        IERC20(token).transfer(owner, profit); // Transfer profit to owner
        IERC20(token).transfer(msg.sender, _loanAmount); // Repay the flash loan
    }
}
